require "slack-ruby-client"
require "async"
require "open-uri"
require "cgi"
require "json"
require "logger"
require "fileutils"
require "open3"
require "nice_http"
require "nice_hash"

require_relative "slack/smart-bot/comm"
require_relative "slack/smart-bot/listen"
require_relative "slack/smart-bot/treat_message"
require_relative "slack/smart-bot/process_first"
require_relative "slack/smart-bot/process"
require_relative "slack/smart-bot/utils"

TESTING_SLACK_SMART_BOT ||= false
unless TESTING_SLACK_SMART_BOT
  if ARGV.size == 0
    CHANNEL = MASTER_CHANNEL
    ON_MASTER_BOT = true
    ADMIN_USERS = MASTER_USERS
    RULES_FILE = "#{$0.gsub(".rb", "_rules.rb")}" unless defined?(RULES_FILE)
    unless File.exist?(RULES_FILE)
      default_rules = (__FILE__).gsub(/\.rb$/, "_rules.rb")
      FileUtils.copy_file(default_rules, RULES_FILE)
    end
    STATUS_INIT = :on
    SHORTCUTS_FILE = "slack-smart-bot_shortcuts_#{CHANNEL}.rb".gsub(" ", "_")
  else
    ON_MASTER_BOT = false
    CHANNEL = ARGV[0]
    ADMIN_USERS = ARGV[1].split(",")
    RULES_FILE = ARGV[2]
    STATUS_INIT = ARGV[3].to_sym
    SHORTCUTS_FILE = "slack-smart-bot_shortcuts_#{CHANNEL}.rb".gsub(" ", "_")
  end
end

class SlackSmartBot
  attr_accessor :config, :client
  attr_reader :master_bot_id, :channel_id
  geml = Gem.loaded_specs.values.select { |x| x.name == "slack-smart-bot" }[0]
  if geml.nil?
    version = ""
  else
    version = geml.version.to_s
  end
  VERSION = version

  def initialize(config)
    Dir.mkdir("./logs") unless Dir.exist?("./logs")
    Dir.mkdir("./shortcuts") unless Dir.exist?("./shortcuts")
    Dir.mkdir("./routines") unless Dir.exist?("./routines")
    logfile = File.basename(RULES_FILE.gsub("_rules_", "_logs_"), ".rb") + ".log"
    @logger = Logger.new("./logs/#{logfile}")
    config_log = config.dup
    config_log.delete(:token)
    config[:silent] = false unless config.key?(:silent)
    config[:testing] = false unless config.key?(:testing)
    @logger.info "Initializing bot: #{config_log.inspect}"

    File.new("./buffer.log", "w") if config[:testing]

    config[:channel] = CHANNEL
    self.config = config

    Slack.configure do |conf|
      conf.token = config[:token]
    end
    restarts = 0
    created = false
    while restarts < 200 and !created
      begin
        @logger.info "Connecting #{config_log.inspect}"
        self.client = Slack::RealTime::Client.new(start_method: :rtm_connect)
        created = true
      rescue Exception => e
        restarts += 1
        if restarts < 200
          @logger.fatal "*" * 50
          @logger.fatal "Rescued on creation: #{e.inspect}"
          @logger.info "Waiting 60 seconds to retry. restarts: #{restarts}"
          puts "#{Time.now}: Not able to create client. Waiting 60 seconds to retry: #{config_log.inspect}"
          sleep 60
        else
          exit!
        end
      end
    end

    @listening = Array.new

    @bots_created = Hash.new()
    @shortcuts = Hash.new()
    @shortcuts[:all] = Hash.new()
    @rules_imported = Hash.new()
    @routines = Hash.new()

    if File.exist?("./shortcuts/#{SHORTCUTS_FILE}")
      file_sc = IO.readlines("./shortcuts/#{SHORTCUTS_FILE}").join
      unless file_sc.to_s() == ""
        @shortcuts = eval(file_sc)
      end
    end

    get_routines()

    if ON_MASTER_BOT and File.exist?($0.gsub(".rb", "_bots.rb"))
      get_bots_created()
      if @bots_created.kind_of?(Hash)
        @bots_created.each { |key, value|
          if !value.key?(:cloud) or (value.key?(:cloud) and value[:cloud] == false)
            @logger.info "ruby #{$0} \"#{value[:channel_name]}\" \"#{value[:admins]}\" \"#{value[:rules_file]}\" #{value[:status].to_sym}"
            t = Thread.new do
              `ruby #{$0} \"#{value[:channel_name]}\" \"#{value[:admins]}\" \"#{value[:rules_file]}\" #{value[:status].to_sym}`
            end
            value[:thread] = t
          end
        }
      end
    end

    # rules imported only for DM
    if ON_MASTER_BOT and File.exist?("./rules/rules_imported.rb")
      file_conf = IO.readlines("./rules/rules_imported.rb").join
      unless file_conf.to_s() == ""
        @rules_imported = eval(file_conf)
      end
    end

    begin
      user_info = client.web_client.users_info(user: "#{"@" if config[:nick][0] != "@"}#{config[:nick]}")
      config[:nick_id] = user_info.user.id
    rescue Slack::Web::Api::Errors::TooManyRequestsError
      @logger.fatal "TooManyRequestsError"
      abort("TooManyRequestsError please re run the bot and be sure of executing first: killall ruby")
    rescue Exception => stack
      @logger.fatal stack
      abort("The bot user specified on settings: #{config[:nick]}, doesn't exist on Slack. Execution aborted")
    end

    begin
      @admin_users_id = []
      ADMIN_USERS.each do |au|
        user_info = client.web_client.users_info(user: "@#{au}")
        @admin_users_id << user_info.user.id
      end
    rescue Slack::Web::Api::Errors::TooManyRequestsError
      @logger.fatal "TooManyRequestsError"
      abort("TooManyRequestsError please re run the bot and be sure of executing first: killall ruby")
    rescue Exception => stack
      abort("The admin user specified on settings: #{ADMIN_USERS.join(", ")}, doesn't exist on Slack. Execution aborted")
    end

    client.on :hello do
      m = "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."
      puts m
      @logger.info m
      gems_remote = `gem list slack-smart-bot --remote`
      version_remote = gems_remote.to_s().scan(/slack-smart-bot \((\d+\.\d+\.\d+)/).join
      version_message = ""
      if version_remote != VERSION
        version_message = ". There is a new available version: #{version_remote}."
      end
      unless config[:silent]
        respond "Smart Bot started v#{VERSION}#{version_message}\nIf you want to know what I can do for you: `bot help`.\n`bot rules` if you want to display just the specific rules of this channel.\nYou can talk to me privately if you prefer it."
      end
      @routines.each do |ch, rout|
        rout.each do |k, v|
          if !v[:running] and v[:channel_name] == CHANNEL
            create_routine_thread(k)
          end
        end
      end
    end

    @status = STATUS_INIT
    @questions = Hash.new()
    @channels_id = Hash.new()
    @channels_name = Hash.new()
    get_channels_name_and_id()
    @channel_id = @channels_id[CHANNEL].dup
    @master_bot_id = @channels_id[MASTER_CHANNEL].dup

    get_routines()
    if @routines.key?(@channel_id)
      @routines[@channel_id].each do |k, v|
        @routines[@channel_id][k][:running] = false
      end
    end
    update_routines()

    client.on :close do |_data|
      m = "Connection closing, exiting. #{Time.now}"
      @logger.info m
      @logger.info _data
    end

    client.on :closed do |_data|
      m = "Connection has been disconnected. #{Time.now}"
      @logger.info m
      @logger.info _data
    end

    self
  end

  private :update_bots_file, :get_bots_created, :get_channels_name_and_id, :update_shortcuts_file
end
