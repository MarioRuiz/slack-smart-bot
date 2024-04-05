SP_COMPARE_NUMBERS_AS_STRINGS = false #nice_hash

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
require "cgi"
require "yaml"
require "nokogiri"
require 'tiktoken_ruby'

require_relative "slack/smart-bot/config"
require_relative "slack/smart-bot/comm"
require_relative "slack/smart-bot/listen"
require_relative "slack/smart-bot/treat_message"
require_relative "slack/smart-bot/process_first"
require_relative "slack/smart-bot/commands"
require_relative "slack/smart-bot/process"
require_relative "slack/smart-bot/utils"
require_relative "slack/smart-bot/ai"

ADMIN_USERS = MASTER_USERS if defined?(MASTER_USERS) # for bg compatibility

class SlackSmartBot
  attr_accessor :config, :client, :client_user, :client_granular
  attr_reader :master_bot_id, :channel_id
  geml = Gem.loaded_specs.values.select { |x| x.name == "slack-smart-bot" }[0]
  if geml.nil?
    version = ""
  else
    version = geml.version.to_s
  end
  VERSION = version
  TIMEOUT_LISTENING = 60 * 30 # 30 minutes

  # Initializes the Slack Smart Bot with the given configuration.
  # Check the README for more information on the configuration options.
  # and lib/slack/smart-bot/config.rb for the default values.
  def initialize(config)
    config_defaults = SlackSmartBot::Config.new()
    abort "The config supplied is not correct. You need to supply a hash with the correct keys and values. The keys are: #{config_defaults.to_h.keys.join(", ")}" unless config.is_a?(Hash)
    # when simulate true for testing purposes: client, web_client, nick, nick_id, git
    config_check = config.deep_copy
    [:client, :web_client, :nick, :nick_id, :git, :allow_access, :authorizations].each do |key|
      config_check.delete(key)
    end
    result_config = NiceHash.compare_structure(config_check, config_defaults.to_h)
    abort "The config supplied is not correct. You need to supply a hash with the correct keys and values. The keys are: #{config_defaults.to_h.keys.join(", ")}" unless result_config

    config = config_defaults.to_h.nice_merge(config)

    config.path.chop! if config.path[-1] == "/"
    config[:jira][:host] = "https://#{config[:jira][:host]}" unless config[:jira][:host] == "" or config[:jira][:host].match?(/^http/)
    config[:github][:host] = "https://#{config[:github][:host]}" unless config[:github][:host] == "" or config[:github][:host].match?(/^http/)
    config[:public_holidays][:host] = "https://#{config[:public_holidays][:host]}" unless config[:public_holidays][:host] == "" or config[:public_holidays][:host].match?(/^http/)

    if config.path.to_s != "" and config.file.to_s == ""
      config.file = File.basename($0)
    end
    if config.key?(:file) and config.file != ""
      config.file_path = "#{config.path}/#{config.file}"
    else
      config.file_path = $0
      config.file = File.basename(config.file_path)
      config.path = File.dirname(config.file_path)
    end
    if config.stats
      Dir.mkdir("#{config.path}/stats") unless Dir.exist?("#{config.path}/stats")
      config.stats_path = "#{config.path}/stats/#{config.file.gsub(".rb", ".stats")}"
    end
    Dir.mkdir("#{config.path}/logs") unless Dir.exist?("#{config.path}/logs")
    Dir.mkdir("#{config.path}/shortcuts") unless Dir.exist?("#{config.path}/shortcuts")
    Dir.mkdir("#{config.path}/routines") unless Dir.exist?("#{config.path}/routines")
    Dir.mkdir("#{config.path}/announcements") unless Dir.exist?("#{config.path}/announcements")
    Dir.mkdir("#{config.path}/shares") unless Dir.exist?("#{config.path}/shares")
    Dir.mkdir("#{config.path}/rules") unless Dir.exist?("#{config.path}/rules")
    Dir.mkdir("#{config.path}/vacations") unless Dir.exist?("#{config.path}/vacations")
    Dir.mkdir("#{config.path}/teams") unless Dir.exist?("#{config.path}/teams")
    Dir.mkdir("#{config.path}/personal_settings") unless Dir.exist?("#{config.path}/personal_settings")
    Dir.mkdir("#{config.path}/openai") unless Dir.exist?("#{config.path}/openai")

    File.delete("#{config.path}/config_tmp.status") if File.exist?("#{config.path}/config_tmp.status")

    if !config.simulate
      if (!config.key?(:token) or config.token.to_s == "")
        abort "You need to supply a valid token key on the settings. key: :token"
      elsif (!config.key?(:user_token) or config.user_token.to_s == "")
        abort "You need to supply a valid user_token key on the settings. key: :user_token"
      elsif (!config.key?(:granular_token) or config.granular_token.to_s == "")
        abort "You need to supply a valid granular_token key on the settings. key: :granular_token"
      end
    end

    resp = get_smartbot_team_info(config[:token])
    if resp.key?(:team) and resp[:team].key?(:enterprise_id)
      config.team_id = resp[:team][:enterprise_id]
    else
      config.team_id = resp.team.id
    end

    config.masters = MASTER_USERS if config.masters.to_s == "" and defined?(MASTER_USERS)
    config.team_id_masters ||= []
    config.team_id_admins ||= []

    config.master_channel = MASTER_CHANNEL if config.master_channel.to_s == "" and defined?(MASTER_CHANNEL)

    if ARGV.size == 0 or (config.file.to_s != "" and config.file.to_s != File.basename($0))
      config.rules_file = "#{config.file.gsub(".rb", "_rules.rb")}" unless config.rules_file.to_s != ""
      unless File.exist?(config.path + "/" + config.rules_file)
        default_rules = (__FILE__).gsub(/\.rb$/, "_rules.rb")
        FileUtils.copy_file(default_rules, config.path + "/" + config.rules_file)
      end
      config.admins = config.masters.dup unless !config.admins.empty?
      config.team_id_admins = config.team_id_masters.dup unless !config.team_id_admins.empty?
      config.channel = config.master_channel unless config.channel.to_s != ""
      config.status_init = :on unless config.status_init.to_s != ""
    else
      config.rules_file = ARGV[2]
      config.admins = ARGV[1].split(",")
      config.channel = ARGV[0]
      config.status_init = ARGV[3].to_sym
    end
    if config.team_id_admins.size != config.admins.size and !config.admins.empty?
        config.admins.each do |name|
          if name.match?(/^[A-Z0-9]{7,11}_/)
            config.team_id_admins << name
          else
            config.team_id_admins << "#{config.team_id}_#{name}"
          end
        end
    end
    config.team_id_admins.uniq!
    config.admins.uniq!

    config.rules_file[0] = "" if config.rules_file[0] == "."
    config.rules_file = "/" + config.rules_file if config.rules_file[0] != "/"

    config.shortcuts_file = "slack-smart-bot_shortcuts_#{config.channel}.yaml".gsub(" ", "_")
    if config.channel == config.master_channel
      config.on_master_bot = true
      config.start_bots = true unless config.key?(:start_bots)
    else
      config.on_master_bot = false
    end

    if (!config.masters.is_a?(Array) or !config.team_id_masters.is_a?(Array)) or
      (config.masters + config.team_id_masters).empty?
      message = "You need to supply a masters array on the settings containing the user names of the master admins, for example: [peter]. key: :masters"
      message += " or a team_id_masters array containing the team_id and user names of the master admins, for example: [TJDFJKD34_peter]. key: :team_id_masters"
      abort message
    elsif !config.key?(:master_channel) or config.master_channel.to_s == ""
      abort "You need to supply a master_channel on the settings. key: :master_channel"
    elsif !config.key?(:channel) or config.channel.to_s == ""
      abort "You need to supply a bot channel name on the settings. key: :channel"
    end

    logfile = File.basename(config.rules_file.gsub("_rules_", "_logs_"), ".rb") + ".log"
    config.log_file = logfile
    @logger = Logger.new("#{config.path}/logs/#{logfile}")
    @last_respond = Time.now

    #todo: consider putting this on a method
    config_log = config.deep_copy
    config_log.delete(:token)
    config_log.delete(:user_token)
    config_log.delete(:granular_token)
    config_log.delete(:authorizations)
    config_log.jira.password = "********" if config_log.key?(:jira) and config_log.jira.key?(:password)
    config_log.github.token = "********" if config_log.key?(:github) and config_log.github.key?(:token)
    config_log.public_holidays.api_key = "********" if config_log.key?(:public_holidays) and config_log.public_holidays.key?(:api_key)
    config_log.encryption[:key] = "********" if config_log.key?(:encryption) and config_log.encryption[:key].to_s != ""
    config_log.encryption.iv = "********" if config_log.key?(:encryption) and config_log.encryption.iv.to_s != ""
    config_log.ai.open_ai.access_token = "********" if config_log.key?(:ai) and config_log.ai.key?(:open_ai) and config_log.ai.open_ai.key?(:access_token)
    config_log.ai.open_ai.chat_gpt.access_token = "********" if config_log.key?(:ai) and config_log.ai.key?(:open_ai) and config_log.ai.open_ai.key?(:chat_gpt) and config_log.ai.open_ai.chat_gpt.key?(:access_token)
    config_log.ai.open_ai.dall_e.access_token = "********" if config_log.key?(:ai) and config_log.ai.key?(:open_ai) and config_log.ai.open_ai.key?(:dall_e) and config_log.ai.open_ai.dall_e.key?(:access_token)
    config_log.ai.open_ai.whisper.access_token = "********" if config_log.key?(:ai) and config_log.ai.key?(:open_ai) and config_log.ai.open_ai.key?(:whisper) and config_log.ai.open_ai.whisper.key?(:access_token)
    config_log.ai.open_ai.models.access_token = "********" if config_log.key?(:ai) and config_log.ai.key?(:open_ai) and config_log.ai.open_ai.key?(:models) and config_log.ai.open_ai.models.key?(:access_token)
    config_log.ldap.auth.password = "********" if config_log.key?(:ldap) and config_log.ldap.key?(:auth) and config_log.ldap.auth.key?(:password)
    @config_log = config_log.deep_copy
    @logger.info "Initializing bot: #{@config_log.inspect}"

    File.new("#{config.path}/buffer.log", "w") if config[:testing] and config.on_master_bot
    File.new("#{config.path}/buffer_complete.log", "w") if config[:simulate] and config.on_master_bot

    self.config = config

    save_status :off, :initializing, "Initializing bot: #{config_log.inspect}"

    unless config.simulate and config.key?(:client)
      Slack.configure do |conf|
        conf.token = config[:token]
      end
    end
    unless (config.simulate and config.key?(:client)) or config.user_token.nil? or config.user_token.empty?
      begin
        self.client_user = Slack::Web::Client.new(token: config.user_token)
        self.client_user.auth_test
      rescue Exception => e
        @logger.fatal "*" * 50
        @logger.fatal "Rescued on creation client_user: #{e.inspect}"
        self.client_user = nil
        abort "Rescued on creation client_user. You need to supply a valid user_token key on the settings. key: :user_token.\n#{e.inspect}"
      end
    else
      self.client_user = nil
    end

    unless (config.simulate and config.key?(:client)) or config.granular_token.nil? or config.granular_token.empty?
      begin
        self.client_granular = Slack::Web::Client.new(token: config.granular_token)
        self.client_granular.auth_test
      rescue Exception => e
        @logger.fatal "*" * 50
        @logger.fatal "Rescued on creation client_granular: #{e.inspect}"
        self.client_granular = nil
        abort "Rescued on creation client_granular. You need to supply a valid granular_token key on the settings. key: :granular_token.\n#{e.inspect}"
      end
    else
      self.client_granular = nil
    end

    restarts = 0
    created = false
    while restarts < 200 and !created
      begin
        @logger.info "Connecting #{config_log.inspect}"
        save_status :off, :connecting, "Connecting #{config_log.inspect}"
        if config.simulate and config.key?(:client)
          self.client = config.client
        else
          if config.logrtm
            logrtmname = "#{config.path}/logs/rtm_#{config.channel}.log"
            File.delete(logrtmname) if File.exist?(logrtmname)
            @logrtm = Logger.new(logrtmname)
            self.client = Slack::RealTime::Client.new(start_method: :rtm_connect, logger: @logrtm)
          else
            self.client = Slack::RealTime::Client.new(start_method: :rtm_connect)
          end
        end
        created = true
      rescue Exception => e
        restarts += 1
        if restarts < 200
          @logger.fatal "*" * 50
          @logger.fatal "Rescued on creation: #{e.inspect}"
          @logger.info "Waiting 60 seconds to retry. restarts: #{restarts}"
          puts "#{Time.now}: Not able to create client. Waiting 60 seconds to retry: #{config_log.inspect}"
          save_status :off, :waiting, "Not able to create client. Waiting 60 seconds to retry: #{config_log.inspect}"

          sleep 60
        else
          exit!
        end
      end
    end

    if config.team_id_masters.empty?
      config.masters.each_with_index do |name, i|
        if name.match?(/^[A-Z0-9]{7,11}_/)
          config.team_id_masters << name
          config.masters[i] = name.split("_")[1..-1].join("_")
        else
          config.team_id_masters << "#{config.team_id}_#{name}"
        end
      end
    else
      config.masters = []
      config.team_id_masters.each_with_index do |tid_name, i|
        name = tid_name.split("_")[1..-1].join("_")
        config.masters << name
      end
    end

    @listening = Hash.new()
    @listening[:threads] = Hash.new() #[thread_ts] => channel_id

    @bots_created = Hash.new()
    @shortcuts = Hash.new()
    @shortcuts[:all] = Hash.new()
    @shortcuts_global = Hash.new()
    @shortcuts_global[:all] = Hash.new()
    @rules_imported = Hash.new()
    @routines = Hash.new()
    @repls = Hash.new()
    @run_repls = Hash.new()
    @users = Hash.new()
    @announcements = Hash.new()
    @shares = Hash.new()
    @last_status_change = Time.now
    @vacations_check = (Time.now - 3600).strftime("%Y%m%d%H")
    @announcements_activity_after = Hash.new()
    @public_holidays = Hash.new()
    @loops = Hash.new()
    @ai_gpt ||= {}
    @active_chat_gpt_sessions = Hash.new()
    @chat_gpt_collaborating = Hash.new()
    @open_ai = Hash.new()
    @open_ai_models = []
    @slack_bots = Hash.new()

    @ldap = nil
    begin
      if config.ldap.key?(:host) and config.ldap[:host].to_s != ""
        require 'net/ldap'
        if config.ldap.key?(:auth) and config.ldap[:auth].key?(:user) and config.ldap[:auth][:user].to_s != ""
          @ldap = Net::LDAP.new(host: config.ldap.host, port: config.ldap.port, auth: config.ldap.auth)
        else
          @ldap = Net::LDAP.new(host: config.ldap.host, port: config.ldap.port)
        end
      end
    rescue Exception => e
      @logger.fatal "Rescued on creation ldap: #{e.inspect}"
      @ldap = nil
    end

    if (config.on_master_bot and !File.exist?("#{config.path}/status/version.txt")) or
       (config.on_master_bot and File.exist?("#{config.path}/status/version.txt") and
        Gem::Version.new(File.read("#{config.path}/status/version.txt").to_s) <= Gem::Version.new("1.15.0"))
      upgrade_to_use_team_ids()
    end

    if File.exist?("#{config.path}/shortcuts/#{config.shortcuts_file}".gsub(".yaml", ".rb")) #backwards compatible
      file_conf = IO.readlines("#{config.path}/shortcuts/#{config.shortcuts_file}".gsub(".yaml", ".rb")).join
      if file_conf.to_s() == ""
        @shortcuts = {}
      else
        @shortcuts = eval(file_conf)
      end
      File.open("#{config.path}/shortcuts/#{config.shortcuts_file}", "w") { |file| file.write(@shortcuts.to_yaml) }
      File.delete("#{config.path}/shortcuts/#{config.shortcuts_file}".gsub(".yaml", ".rb"))
    elsif File.exist?("#{config.path}/shortcuts/#{config.shortcuts_file}")
      @shortcuts = YAML.load(File.read("#{config.path}/shortcuts/#{config.shortcuts_file}"))
    end
    if File.exist?("#{config.path}/shortcuts/shortcuts_global.rb") #backwards compatible
      file_sc = IO.readlines("#{config.path}/shortcuts/shortcuts_global.rb").join
      @shortcuts_global = {}
      unless file_sc.to_s() == ""
        @shortcuts_global = eval(file_sc)
      end
      File.open("#{config.path}/shortcuts/shortcuts_global.yaml", "w") { |file| file.write(@shortcuts_global.to_yaml) }
      File.delete("#{config.path}/shortcuts/shortcuts_global.rb")
    elsif File.exist?("#{config.path}/shortcuts/shortcuts_global.yaml")
      @shortcuts_global = YAML.load(File.read("#{config.path}/shortcuts/shortcuts_global.yaml"))
    end

    get_routines()
    get_repls()

    if config.on_master_bot and (File.exist?(config.file_path.gsub(".rb", "_bots.rb")) or File.exist?(config.file_path.gsub(".rb", "_bots.yaml")))
      get_bots_created()
      if @bots_created.kind_of?(Hash) and config.start_bots
        @bots_created.each { |key, value|
          if !value.key?(:cloud) or (value.key?(:cloud) and value[:cloud] == false)
            if value.key?(:silent) and value.silent != config.silent
              silent = value.silent
            else
              silent = config.silent
            end
            @logger.info "BOT_SILENT=#{silent} ruby #{config.file_path} \"#{value[:channel_name]}\" \"#{value[:admins]}\" \"#{value[:rules_file]}\" #{value[:status].to_sym}"
            puts "Starting #{value[:channel_name]} Smart Bot"
            save_status :off, :starting, "Starting #{value[:channel_name]} Smart Bot"

            t = Thread.new do
              `BOT_SILENT=#{silent} ruby #{config.file_path} \"#{value[:channel_name]}\" \"#{value[:admins]}\" \"#{value[:rules_file]}\" #{value[:status].to_sym}`
            end
            value[:thread] = t
            sleep value[:admins].size
          end
        }
      end
    end
    general_rules_file = "/rules/general_rules.rb"
    general_commands_file = "/rules/general_commands.rb"
    default_general_rules = (__FILE__).gsub(/\/slack-smart-bot\.rb$/, "/slack-smart-bot_general_rules.rb")
    default_general_commands = (__FILE__).gsub(/\/slack-smart-bot\.rb$/, "/slack-smart-bot_general_commands.rb")
    FileUtils.copy_file(default_general_rules, config.path + general_rules_file) unless File.exist?(config.path + general_rules_file)
    FileUtils.copy_file(default_general_commands, config.path + general_commands_file) unless File.exist?(config.path + general_commands_file)

    get_rules_imported()
    begin
      #todo: take in consideration the case that the value supplied on config.masters and config.admins are the ids and not the user names
      @admin_users_id = []
      @master_admin_users_id = []
      config.team_id_admins.each do |au|
        user_info = get_user_info("@#{au}")
        @admin_users_id << user_info.user.id
        if config.team_id_masters.include?(au)
          @master_admin_users_id << user_info.user.id
        end
        sleep 1
      end
      (config.team_id_masters - config.team_id_admins).each do |au|
        user_info = get_user_info("@#{au}")
        @master_admin_users_id << user_info.user.id unless user_info.nil?
        sleep 1
      end
      @admin_users_id.uniq!
      @master_admin_users_id.uniq!

    rescue Slack::Web::Api::Errors::TooManyRequestsError
      @logger.fatal "TooManyRequestsError"
      save_status :off, :TooManyRequestsError, "TooManyRequestsError please re run the bot and be sure of executing first: killall ruby"
      abort("TooManyRequestsError please re run the bot and be sure of executing first: killall ruby")
    rescue Exception => stack
      pp stack if config.testing
      save_status :off, :wrong_admin_user, "The admin user specified on settings: #{config.admins.join(", ")}, doesn't exist on Slack. Execution aborted"
      abort("The admin user specified on settings: #{config.admins.join(", ")}, doesn't exist on Slack. Execution aborted")
    end

    if config.simulate and config.key?(:client)
      event_hello()
    else
      client.on :hello do
        event_hello()
      end
    end

    @status = config.status_init
    @questions = Hash.new()
    @answer = Hash.new()
    @repl_sessions = Hash.new()
    @datetime_general_commands = 0
    @channels_id = Hash.new()
    @channels_name = Hash.new()
    @channels_creator = Hash.new()
    @channels_list = Hash.new()
    get_channels_name_and_id()
    @channel_id = @channels_id[config.channel].dup
    @master_bot_id = @channels_id[config.master_channel].dup

    Dir.mkdir("#{config.path}/rules/#{@channel_id}") unless Dir.exist?("#{config.path}/rules/#{@channel_id}/")

    get_routines()
    get_repls()
    get_shares()
    get_admins_channels()
    get_access_channels()
    get_vacations()
    get_openai_sessions()
    get_personal_settings()

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
            create_routine_thread(k, v)
          end
        end
      end
    else
      client.on :close do |_data|
        m = "Connection closing, exiting. #{Time.now}"
        @logger.info m
        @logger.info _data
        #save_status :off, :closing, "Connection closing, exiting." #todo: don't notify for the moment, remove when checked
      end

      client.on :closed do |_data|
        m = "Connection has been disconnected. #{Time.now}"
        @logger.info m
        @logger.info _data
        save_status :off, :disconnected, "Connection has been disconnected."
      end
    end
    self
  end

  private :update_bots_file, :get_bots_created, :get_channels_name_and_id, :update_shortcuts_file
end
