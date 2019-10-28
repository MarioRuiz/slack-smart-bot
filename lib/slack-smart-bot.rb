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

ADMIN_USERS = MASTER_USERS if defined?(MASTER_USERS) # for bg compatibility
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
    if config.key?(:path) and config[:path] != ''
      config.path.chop! if config.path[-1]=="/"
    else
      config[:path] = '.'
    end
    config[:silent] = false unless config.key?(:silent)
    config[:testing] = false unless config.key?(:testing)
    config[:simulate] = false unless config.key?(:simulate)
    if config.path.to_s!='' and config.file.to_s==''
      config.file = File.basename($0)
    end
    if config.key?(:file) and config.file!=''
      config.file_path = "#{config.path}/#{config.file}"
    else
      config.file_path = $0
      config.file = File.basename(config.file_path)
      config.path = File.dirname(config.file_path)
    end
    Dir.mkdir("#{config.path}/logs") unless Dir.exist?("#{config.path}/logs")
    Dir.mkdir("#{config.path}/shortcuts") unless Dir.exist?("#{config.path}/shortcuts")
    Dir.mkdir("#{config.path}/routines") unless Dir.exist?("#{config.path}/routines")

    config.masters = MASTER_USERS if config.masters.to_s=='' and defined?(MASTER_USERS)
    config.master_channel = MASTER_CHANNEL if config.master_channel.to_s=='' and defined?(MASTER_CHANNEL)

    if ARGV.size == 0 or (config.file.to_s!='' and config.file.to_s!=File.basename($0))
      config.rules_file = "#{config.file.gsub(".rb", "_rules.rb")}" unless config.rules_file.to_s!=''
      unless File.exist?(config.path + '/' + config.rules_file)
        default_rules = (__FILE__).gsub(/\.rb$/, "_rules.rb")
        FileUtils.copy_file(default_rules, config.path + '/' + config.rules_file)
      end
      config.admins = config.masters unless config.admins.to_s!=''
      config.channel = config.master_channel unless config.channel.to_s!=''
      config.status_init = :on unless config.status_init.to_s!=''
    else
      config.rules_file = ARGV[2]
      config.admins = ARGV[1].split(",")
      config.channel = ARGV[0]
      config.status_init = ARGV[3].to_sym
    end
    config.rules_file[0]='' if config.rules_file[0]=='.'
    config.rules_file='/'+config.rules_file if config.rules_file[0]!='/'

    config.shortcuts_file = "slack-smart-bot_shortcuts_#{config.channel}.rb".gsub(" ", "_")
    if config.channel == config.master_channel
      config.on_master_bot = true
      config.start_bots = true unless config.key?(:start_bots)
    else
      config.on_master_bot = false
    end

    if !config.key?(:token) or config.token.to_s == ''
      abort "You need to supply a valid token key on the settings. key: :token"
    elsif !config.key?(:masters) or !config.masters.is_a?(Array) or config.masters.size == 0
      abort "You need to supply a masters array on the settings containing the user names of the master admins. key: :masters"
    elsif !config.key?(:master_channel) or config.master_channel.to_s == ''
      abort "You need to supply a master_channel on the settings. key: :master_channel"
    elsif !config.key?(:channel) or config.channel.to_s == ''
      abort "You need to supply a bot channel name on the settings. key: :channel"
    end



    logfile = File.basename(config.rules_file.gsub("_rules_", "_logs_"), ".rb") + ".log"
    @logger = Logger.new("#{config.path}/logs/#{logfile}")
    @logger.info ARGV.inspect #Jal

    config_log = config.dup
    config_log.delete(:token)
    @logger.info "Initializing bot: #{config_log.inspect}"

    File.new("#{config.path}/buffer.log", "w") if config[:testing] and config.on_master_bot
    File.new("#{config.path}/buffer_complete.log", "w") if config[:simulate] and config.on_master_bot

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

    if File.exist?("#{config.path}/shortcuts/#{config.shortcuts_file}")
      file_sc = IO.readlines("#{config.path}/shortcuts/#{config.shortcuts_file}").join
      unless file_sc.to_s() == ""
        @shortcuts = eval(file_sc)
      end
    end

    get_routines()

    if config.on_master_bot and File.exist?(config.file_path.gsub(".rb", "_bots.rb"))
      get_bots_created()
      if @bots_created.kind_of?(Hash) and config.start_bots
        @bots_created.each { |key, value|
          if !value.key?(:cloud) or (value.key?(:cloud) and value[:cloud] == false)
            @logger.info "ruby #{config.file_path} \"#{value[:channel_name]}\" \"#{value[:admins]}\" \"#{value[:rules_file]}\" #{value[:status].to_sym}"
            t = Thread.new do
              `ruby #{config.file_path} \"#{value[:channel_name]}\" \"#{value[:admins]}\" \"#{value[:rules_file]}\" #{value[:status].to_sym}`
            end
            value[:thread] = t
          end
        }
      end
    end

    # rules imported only for DM
    if config.on_master_bot and File.exist?("#{config.path}/rules/rules_imported.rb")
      file_conf = IO.readlines("#{config.path}/rules/rules_imported.rb").join
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
      config.admins.each do |au|
        user_info = client.web_client.users_info(user: "@#{au}")
        @admin_users_id << user_info.user.id
      end
    rescue Slack::Web::Api::Errors::TooManyRequestsError
      @logger.fatal "TooManyRequestsError"
      abort("TooManyRequestsError please re run the bot and be sure of executing first: killall ruby")
    rescue Exception => stack
      abort("The admin user specified on settings: #{config.admins.join(", ")}, doesn't exist on Slack. Execution aborted")
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
          if !v[:running] and v[:channel_name] == config.channel
            create_routine_thread(k)
          end
        end
      end
    end

    @status = config.status_init
    @questions = Hash.new()
    @channels_id = Hash.new()
    @channels_name = Hash.new()
    get_channels_name_and_id()
    @channel_id = @channels_id[config.channel].dup
    @master_bot_id = @channels_id[config.master_channel].dup

    get_routines()
    if @routines.key?(@channel_id)
      @routines[@channel_id].each do |k, v|
        @routines[@channel_id][k][:running] = false
      end
    end
    update_routines()

    if config.simulate #not necessary to wait until bot started (client.on :hello)
      @routines.each do |ch, rout|
        rout.each do |k, v|
          if !v[:running] and v[:channel_name] == config.channel
            create_routine_thread(k)
          end
        end
      end
    end

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
