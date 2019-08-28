require "slack-ruby-client"
require "async"
require "open-uri"
require "cgi"
require "json"
require "logger"
require "fileutils"
require "open3"

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
else
  ON_MASTER_BOT = false
  CHANNEL = ARGV[0]
  ADMIN_USERS = ARGV[1].split(",")
  RULES_FILE = ARGV[2]
  STATUS_INIT = ARGV[3].to_sym
end

SHORTCUTS_FILE = "slack-smart-bot_shortcuts_#{CHANNEL}.rb".gsub(" ", "_")

class SlackSmartBot
  attr_accessor :config, :client
  attr_reader :master_bot_id, :channel_id
  VERSION = Gem.loaded_specs.values.select { |x| x.name == "slack-smart-bot" }[0].version.to_s

  def initialize(config)
    Dir.mkdir("./logs") unless Dir.exist?("./logs")
    Dir.mkdir("./shortcuts") unless Dir.exist?("./shortcuts")
    logfile = File.basename(RULES_FILE.gsub("_rules_", "_logs_"), ".rb") + ".log"
    @logger = Logger.new("./logs/#{logfile}")
    config_log = config.dup
    config_log.delete(:token)
    config[:silent] = false unless config.key?(:silent)
    @logger.info "Initializing bot: #{config_log.inspect}"

    config[:channel] = CHANNEL
    self.config = config

    Slack.configure do |conf|
      conf.token = config[:token]
    end
    self.client = Slack::RealTime::Client.new(start_method: :rtm_connect)

    @listening = Array.new

    @bots_created = Hash.new()
    @shortcuts = Hash.new()
    @shortcuts[:all] = Hash.new()
    @rules_imported = Hash.new()

    if File.exist?("./shortcuts/#{SHORTCUTS_FILE}")
      file_sc = IO.readlines("./shortcuts/#{SHORTCUTS_FILE}").join
      unless file_sc.to_s() == ""
        @shortcuts = eval(file_sc)
      end
    end

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
    rescue Exception => stack
      @logger.fatal stack
      abort("The bot user specified on settings: #{config[:nick]}, doesn't exist on Slack. Execution aborted")
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
    end

    @status = STATUS_INIT
    @questions = Hash.new()
    @channels_id = Hash.new()
    @channels_name = Hash.new()
    get_channels_name_and_id()
    @channel_id = @channels_id[CHANNEL].dup
    @master_bot_id = @channels_id[MASTER_CHANNEL].dup

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

  def update_bots_file
    file = File.open($0.gsub(".rb", "_bots.rb"), "w")
    bots_created = @bots_created.dup
    bots_created.each { |k, v| v[:thread] = "" }
    file.write bots_created.inspect
    file.close
  end

  def get_bots_created
    if File.exist?($0.gsub(".rb", "_bots.rb"))
      if !defined?(@datetime_bots_created) or @datetime_bots_created!=File.mtime($0.gsub(".rb", "_bots.rb"))
        file_conf = IO.readlines($0.gsub(".rb", "_bots.rb")).join
        if file_conf.to_s() == ""
          @bots_created = {}
        else
          @bots_created = eval(file_conf)
        end
        @datetime_bots_created = File.mtime($0.gsub(".rb", "_bots.rb"))
        @bots_created.each do |k,v| # to be compatible with old versions
          v[:extended] = [] unless v.key?(:extended)
        end
      end
    end
  end

  def update_shortcuts_file
    file = File.open("./shortcuts/#{SHORTCUTS_FILE}", "w")
    file.write @shortcuts.inspect
    file.close
  end

  def update_rules_imported
    file = File.open("./rules/rules_imported.rb", "w")
    file.write @rules_imported.inspect
    file.close
  end

  def get_channels_name_and_id
    #todo: add pagination for case more than 1000 channels on the workspace
    channels = client.web_client.conversations_list(
      types: 'private_channel,public_channel', 
      limit: '1000',
      exclude_archived: 'true').channels

    @channels_id = Hash.new()
    @channels_name = Hash.new()
    channels.each do |ch|
      unless ch.is_archived
        @channels_id[ch.name] = ch.id
        @channels_name[ch.id] = ch.name
      end
    end
  end

  #help: ===================================
  #help:
  #help: *Commands from Channels without a bot:*
  #help:
  #help: ----------------------------------------------
  #help:
  #help: `@BOT_NAME on #CHANNEL_NAME COMMAND`
  #help: `@BOT_NAME #CHANNEL_NAME COMMAND`
  #help:    It will run the supplied command using the rules on the channel supplied.
  #help:    You need to join the specified channel to be able to use those rules.
  #help:    Also you can use this command to call another bot from a channel with a running bot.
  def listen
    @salutations = [config[:nick], config[:nick_id], "bot", "smart"]
    get_bots_created()
    client.on :message do |data|
      if data.channel[0] == "D" or data.channel[0] == "C" or data.channel[0] == "G" #Direct message or Channel or Private Channel
        dest = data.channel
      else # not treated
        dest = nil
      end
      #todo: sometimes data.user is nil, check the problem.
      @logger.warn "!dest is nil. user: #{data.user}, channel: #{data.channel}, message: #{data.text}" if dest.nil?
      
      typem = :dont_treat
      if !dest.nil? and !data.text.nil? and !data.text.to_s.match?(/^\s*$/)
        if data.text.match(/^<@#{config[:nick_id]}>\s(on\s)?<#(\w+)\|(.+)>\s*:?\s*(.*)/im)
          channel_rules = $2
          channel_rules_name = $3
          # to be treated only on the bot of the requested channel
          if @channel_id == channel_rules 
            data.text = $4
            typem = :on_call
          end

        elsif dest == @master_bot_id
          if ON_MASTER_BOT #only to be treated on master mot channel
            typem = :on_master
          end
        elsif @bots_created.key?(dest)
          if @channel_id == dest #only to be treated by the bot on the channel
            typem = :on_bot
          end
        elsif dest[0]=="D" #Direct message
          if ON_MASTER_BOT #only to be treated by master bot
            typem = :on_dm
          end
        elsif dest[0]=="G" #private group
          if ON_MASTER_BOT #only to be treated by master bot
            typem = :on_pg
          end
        elsif dest[0]=='C' 
          #only to be treated on the channel of the bot. excluding running ruby
          if !ON_MASTER_BOT and @bots_created[@channel_id][:extended].include?(@channels_name[dest]) and
            !data.text.match?(/^!?\s*(ruby|code)\s+/)
            typem = :on_extended
          elsif ON_MASTER_BOT and data.text.match?(/^!?\s*(ruby|code)\s+/) #or in case of running ruby, the master bot
            @bots_created.each do |k,v|
              if v.key?(:extended) and v[:extended].include?(@channels_name[dest])
                typem = :on_extended
                break
              end
            end
          end
        end
      end
      
      unless typem == :dont_treat
        begin
          command = data.text

          #todo: when changed @questions user_id then move user_info inside the ifs to avoid calling it when not necessary
          user_info = client.web_client.users_info(user: data.user)
          
          #when added special characters on the message
          if command.size >= 2 and
             ((command[0] == "`" and command[-1] == "`") or (command[0] == "*" and command[-1] == "*") or (command[0] == "_" and command[-1] == "_"))
            command = command[1..-2]
          end

          #ruby file attached
          if !data.files.nil? and data.files.size == 1 and
             (command.match?(/^(ruby|code)\s*$/) or (command.match?(/^\s*$/) and data.files[0].filetype == "ruby") or
              (typem==:on_call and data.files[0].filetype == "ruby"))
            res = Faraday.new("https://files.slack.com", headers: { "Authorization" => "Bearer #{config[:token]}" }).get(data.files[0].url_private)
            command = "#{command} ruby #{res.body.to_s.force_encoding("UTF-8")}"
          end

          if typem == :on_call
            command = "!" + command unless command[0] == "!" or command.match?(/^\s*$/)
            
            #todo: add pagination for case more than 1000 channels on the workspace
            channels = client.web_client.conversations_list(
              types: 'private_channel,public_channel', 
              limit: '1000',
              exclude_archived: 'true').channels
            channel_found = channels.detect { |c| c.name == channel_rules_name }
            members = client.web_client.conversations_members(channel: @channels_id[channel_rules_name]).members unless channel_found.nil?
            if channel_found.nil?
              @logger.fatal "Not possible to find the channel #{channel_rules_name}"
            elsif channel_found.name == MASTER_CHANNEL
              respond "You cannot use the rules from Master Channel on any other channel.", dest
            elsif @status != :on
              respond "The bot in that channel is not :on", dest
            elsif data.user == channel_found.creator or members.include?(data.user)
              res = process_first(user_info.user, command, dest, channel_rules, typem)
            else
              respond "You need to join the channel <##{channel_found.id}> to be able to use the rules.", dest
            end

          elsif @questions.keys.include?(user_info.user.name)
            #todo: @questions key should be the id not the name. change it everywhere
            dest = data.channel
            res = process_first(user_info.user, command, dest, @channel_id, typem)

          elsif ON_MASTER_BOT and typem ==:on_extended and
            command.size > 0 and command[0] != "-"
            # to run ruby only from the master bot for the case more than one extended
            res = process_first(user_info.user, command, dest, @channel_id, typem)

          elsif !ON_MASTER_BOT and @bots_created[@channel_id].key?(:extended) and 
            @bots_created[@channel_id][:extended].include?(@channels_name[data.channel]) and
            command.size > 0 and command[0] != "-"
            res = process_first(user_info.user, command, dest, @channel_id, typem)
          elsif (dest[0] == "D" or @channel_id == data.channel or data.user == config[:nick_id]) and
                command.size > 0 and command[0] != "-"
            res = process_first(user_info.user, command, dest, data.channel, typem)
            # if @botname on #channel_rules: do something
          end
        rescue Exception => stack
          @logger.fatal stack
        end
      end
    end

    @logger.info "Bot listening"
    client.start!
  end

  def process_first(user, text, dest, dchannel, typem)
    nick = user.name
    rules_file = ""

    if typem == :on_call
      rules_file = RULES_FILE

    elsif dest[0] == "C" or dest[0] == "G" # on a channel or private channel
      rules_file = RULES_FILE

      if @rules_imported.key?(user.id) and @rules_imported[user.id].key?(dchannel)
        unless @bots_created.key?(@rules_imported[user.id][dchannel])
          get_bots_created()
        end
        if @bots_created.key?(@rules_imported[user.id][dchannel])
          rules_file = @bots_created[@rules_imported[user.id][dchannel]][:rules_file]
        end
      end
    elsif dest[0] == "D" and @rules_imported.key?(user.id) and @rules_imported[user.id].key?(user.id) #direct message
      unless @bots_created.key?(@rules_imported[user.id][user.id])
        get_bots_created()
      end
      if @bots_created.key?(@rules_imported[user.id][user.id])
        rules_file = @bots_created[@rules_imported[user.id][user.id]][:rules_file]
      end
    end

    if nick == config[:nick] #if message is coming from the bot
      begin
        case text
        when /^Bot has been (closed|killed) by/i
          if CHANNEL == @channels_name[dchannel]
            @logger.info "#{nick}: #{text}"
            exit!
          end
        when /^Changed status on (.+) to :(.+)/i
          channel_name = $1
          status = $2
          if ON_MASTER_BOT or CHANNEL == channel_name
            @bots_created[@channels_id[channel_name]][:status] = status.to_sym
            update_bots_file()
            if CHANNEL == channel_name
              @logger.info "#{nick}: #{text}"
            else #on master bot
              @logger.info "Changed status on #{channel_name} to :#{status}"
            end
          end
        end
        return :next #don't continue analyzing
      rescue Exception => stack
        @logger.fatal stack
        return :next
      end
    end

    #only for shortcuts
    if text.match(/^@?(#{config[:nick]}):*\s+(.+)\s*/im) or
       text.match(/^()!\s*(.+)\s*/im) or
       text.match(/^()<@#{config[:nick_id]}>\s+(.+)\s*/im)
      command = $2
      addexcl = true
    else
      addexcl = false
      command = text.downcase.lstrip.rstrip
    end
    if command.scan(/^(shortcut|sc)\s+(.+)/i).any? or
       (@shortcuts.keys.include?(:all) and @shortcuts[:all].keys.include?(command)) or
       (@shortcuts.keys.include?(nick) and @shortcuts[nick].keys.include?(command))
      command = $2.downcase unless $2.nil?
      if @shortcuts.keys.include?(nick) and @shortcuts[nick].keys.include?(command)
        text = @shortcuts[nick][command].dup
      elsif @shortcuts.keys.include?(:all) and @shortcuts[:all].keys.include?(command)
        text = @shortcuts[:all][command].dup
      else
        respond "Shortcut not found", dest unless dest[0]=="C" and dchannel != dest #on extended channel
        return :next
      end
      text = "!" + text if addexcl and text[0] != "!"
    end

    if @questions.keys.include?(nick)
      command = @questions[nick]
      @questions[nick] = text
    else
      command = text
    end
    begin
      t = Thread.new do
        begin
          processed = process(user, command, dest, dchannel, rules_file, typem)
          @logger.info "command: #{nick}> #{command}" if processed
          on_demand = false
          if command.match(/^@?(#{config[:nick]}):*\s+(.+)/im) or
             command.match(/^()!(.+)/im) or
             command.match(/^()<@#{config[:nick_id]}>\s+(.+)/im)
            command = $2
            on_demand = true
          end
          if @status == :on and
             (@questions.keys.include?(nick) or
              (@listening.include?(nick) and typem!=:on_extended) or
              dest[0] == "D" or on_demand)
            @logger.info "command: #{nick}> #{command}" unless processed
            #todo: verify this

            if dest[0] == "C" or dest[0] == "G" or (dest[0]=="D" and typem==:on_call)
              if typem!=:on_call and @rules_imported.key?(user.id) and @rules_imported[user.id].key?(dchannel)
                if @bots_created.key?(@rules_imported[user.id][dchannel])
                  if @bots_created[@rules_imported[user.id][dchannel]][:status] != :on
                    respond "The bot on that channel is not :on", dest
                    rules_file = ""
                  end
                end
              end
              unless rules_file.empty?
                begin
                  eval(File.new(rules_file).read) if File.exist?(rules_file)
                rescue Exception => stack
                  @logger.fatal "ERROR ON RULES FILE: #{rules_file}"
                  @logger.fatal stack
                end
                if defined?(rules)
                  command[0] = "" if command[0] == "!"
                  command.gsub!(/^@\w+:*\s*/, "")
                  rules(user, command, processed, dest)
                else
                  @logger.warn "It seems like rules method is not defined"
                end
              end
            elsif @rules_imported.key?(user.id) and @rules_imported[user.id].key?(user.id)
              if @bots_created.key?(@rules_imported[user.id][user.id])
                if @bots_created[@rules_imported[user.id][user.id]][:status] == :on
                  begin
                    eval(File.new(rules_file).read) if File.exist?(rules_file)
                  rescue Exception => stack
                    @logger.fatal "ERROR ON imported RULES FILE: #{rules_file}"
                    @logger.fatal stack
                  end
                else
                  respond "The bot on <##{@rules_imported[user.id][user.id]}|#{@bots_created[@rules_imported[user.id][user.id]][:channel_name]}> is not :on", dest
                  rules_file = ""
                end
              end

              unless rules_file.empty?
                if defined?(rules)
                  command[0] = "" if command[0] == "!"
                  command.gsub!(/^@\w+:*\s*/, "")
                  rules(user, command, processed, dest)
                else
                  @logger.warn "It seems like rules method is not defined"
                end
              end
            else
              @logger.info "it is a direct message with no rules file selected so no rules file executed."
              unless processed
                resp = ["what", "huh", "sorry", "what do you mean", "I don't understand"].sample
                respond "#{resp}?", dest
              end
            end
          end
        rescue Exception => stack
          @logger.fatal stack
        end
      end
    rescue => e
      @logger.error "exception: #{e.inspect}"
    end
  end

  #help: ===================================
  #help:
  #help: *General commands:*
  #help:
  def process(user, command, dest, dchannel, rules_file, typem)
    from = user.name
    display_name = user.profile.display_name
    processed = true

    if typem == :on_master or typem == :on_bot or typem ==:on_pg or typem == :on_dm
      case command

      #help: ----------------------------------------------
      #help: `Hello Bot`
      #help: `Hello Smart`
      #help: `Hello THE_NAME_OF_THE_BOT`
      #help:    Also apart of Hello you can use _Hallo, Hi, Hola, What's up, Hey, Hæ_
      #help:    Bot starts listening to you
      #help:    If you want to avoid a single message to be treated by the smart bot, start the message by -
      #help:
      when /^(Hello|Hallo|Hi|Hola|What's\sup|Hey|Hæ)\s(#{@salutations.join("|")})\s*$/i
        if @status == :on
          greetings = ["Hello", "Hallo", "Hi", "Hola", "What's up", "Hey", "Hæ"].sample
          respond "#{greetings} #{display_name}", dest
          if @rules_imported.key?(user.id) and @rules_imported[user.id].key?(user.id) and dest[0] == "D"
            respond "You are using specific rules for channel: <##{@rules_imported[user.id][user.id]}>", dest
          elsif @rules_imported.key?(user.id) and @rules_imported[user.id].key?(dchannel) and (dest[0] == "C" or dest[0] == "G")
            respond "You are using specific rules for channel: <##{@rules_imported[user.id][dchannel]}>", dest
          end
          @listening << from unless @listening.include?(from)
        end

        #help: ----------------------------------------------
        #help: `Bye Bot`
        #help: `Bye Smart`
        #help: `Bye NAME_OF_THE_BOT`
        #help:    Also apart of Bye you can use _Bæ, Good Bye, Adiós, Ciao, Bless, Bless Bless, Adeu_
        #help:    Bot stops listening to you
        #help:
      when /^(Bye|Bæ|Good\sBye|Adiós|Ciao|Bless|Bless\sBless|Adeu)\s(#{@salutations.join("|")})\s*$/i
        if @status == :on
          bye = ["Bye", "Bæ", "Good Bye", "Adiós", "Ciao", "Bless", "Bless bless", "Adeu"].sample
          respond "#{bye} #{display_name}", dest
          @listening.delete(from)
        end

        #help: ----------------------------------------------
        #help: `bot help`
        #help: `bot what can I do?`
        #help: `bot rules`
        #help:    it will display this help
        #help:    `bot rules` will show only the specific rules for this channel.
      when /^bot\s+(rules|help)/i, /^bot,? what can I do/i
        if $1.to_s.match?(/rules/i)
          specific = true
        else
          specific = false
        end
        help_message_rules = ''
        if !specific
          help_message = IO.readlines(__FILE__).join
          if ADMIN_USERS.include?(from) #admin user
            respond "*Commands for administrators:*\n#{help_message.scan(/#\s*help\s*admin:(.*)/).join("\n")}", dest
          end
          if ON_MASTER_BOT and (dest[0] == "C" or dest[0] == "G")
            respond "*Commands only on Master Channel <##{@channels_id[MASTER_CHANNEL]}>:*\n#{help_message.scan(/#\s*help\s*master:(.*)/).join("\n")}", dest
          end
          respond help_message.scan(/#\s*help\s*:(.*)/).join("\n"), dest
        end
        if dest[0] == "C" or dest[0] == "G" # on a channel
          if @rules_imported.key?(user.id) and @rules_imported[user.id].key?(dchannel)
            if @bots_created.key?(@rules_imported[user.id][dchannel])
              respond "*You are using rules from another channel: <##{@rules_imported[user.id][dchannel]}>. These are the specific commands for that channel:*", dest
            end
          end
          help_message_rules = IO.readlines(rules_file).join
          respond help_message_rules.scan(/#\s*help\s*:(.*)/).join("\n"), dest
        elsif dest[0] == "D" and @rules_imported.key?(user.id) and @rules_imported[user.id].key?(user.id) #direct message
          if @bots_created.key?(@rules_imported[user.id][user.id])
            respond "*You are using rules from channel: <##{@rules_imported[user.id][user.id]}>. These are the specific commands for that channel:*", dest
            help_message_rules = IO.readlines(rules_file).join
            respond help_message_rules.scan(/#\s*help\s*:(.*)/).join("\n"), dest
          end
        end
        if specific
          unless rules_file.empty?
            begin
              eval(File.new(rules_file).read) if File.exist?(rules_file)
            end
          end
          if defined?(git_project) and git_project.to_s!='' and help_message_rules != ''
            respond "Git project: #{git_project}", dest
          else
            def git_project() '' end
            def project_folder() '' end
          end
          
        else
          respond "Slack Smart Bot Github project: https://github.com/MarioRuiz/slack-smart-bot", dest
        end

        #help: ===================================
        #help:
        #help: *These commands will run only when on a private conversation with the bot:*
        #help:
        #help: ----------------------------------------------
        #help: `use rules from CHANNEL`
        #help:    it will use the rules from the specified channel.
        #help:    you need to be part of that channel to be able to use the rules.
        #help:
      when /^use rules (from\s+)<#C\w+\|(.+)>/i, /^use rules (from\s+)(.+)/i
        channel = $2
        #todo: add pagination for case more than 1000 channels on the workspace
        channels = client.web_client.conversations_list(
          types: 'private_channel,public_channel', 
          limit: '1000',
          exclude_archived: 'true').channels

        channel_found = channels.detect { |c| c.name == channel }
        members = client.web_client.conversations_members(channel: @channels_id[channel]).members unless channel_found.nil?

        if channel_found.nil?
          respond "The channel you are trying to use doesn't exist", dest
        elsif channel_found.name == MASTER_CHANNEL
          respond "You cannot use the rules from Master Channel on any other channel.", dest
        elsif !@bots_created.key?(@channels_id[channel])
          respond "There is no bot running on that channel.", dest
        elsif @bots_created.key?(@channels_id[channel]) and @bots_created[@channels_id[channel]][:status] != :on
          respond "The bot in that channel is not :on", dest
        else
          if user.id == channel_found.creator or members.include?(user.id)
            @rules_imported[user.id] = {} unless @rules_imported.key?(user.id)
            if dest[0] == "C" or dest[0] == "G" #todo: take in consideration bots that are not master
              @rules_imported[user.id][dchannel] = channel_found.id
            else
              @rules_imported[user.id][user.id] = channel_found.id
            end
            update_rules_imported() if ON_MASTER_BOT
            respond "I'm using now the rules from <##{channel_found.id}>", dest
            def git_project() "" end
            def project_folder() "" end
          else
            respond "You need to join the channel <##{channel_found.id}> to be able to use the rules.", dest
          end
        end

        #help: ----------------------------------------------
        #help: `stop using rules from CHANNEL`
        #help:    it will stop using the rules from the specified channel.
        #help:
      when /^stop using rules (from\s+)<#C\w+\|(.+)>/i, /^stop using rules (from\s+)(.+)/i
        channel = $2
        if @channels_id.key?(channel)
          channel_id = @channels_id[channel]
        else
          channel_id = channel
        end
        if dest[0] == "C" or dest[0] == "G" #channel
          if @rules_imported.key?(user.id) and @rules_imported[user.id].key?(dchannel)
            if @rules_imported[user.id][dchannel] != channel_id
              respond "You are not using those rules.", dest
            else
              @rules_imported[user.id].delete(dchannel)
              update_rules_imported() if ON_MASTER_BOT
              respond "You won't be using those rules from now on.", dest
              def git_project() "" end
              def project_folder() "" end
            end
          else
            respond "You were not using those rules.", dest
          end
        else #direct message
          if @rules_imported.key?(user.id) and @rules_imported[user.id].key?(user.id)
            if @rules_imported[user.id][user.id] != channel_id
              respond "You are not using those rules.", dest
            else
              @rules_imported[user.id].delete(user.id)
              update_rules_imported() if ON_MASTER_BOT
              respond "You won't be using those rules from now on.", dest
              def git_project() "" end
              def project_folder() "" end
            end
          else
            respond "You were not using those rules.", dest
          end
        end

        #helpadmin: ----------------------------------------------
        #helpadmin: `exit bot`
        #helpadmin: `quit bot`
        #helpadmin: `close bot`
        #helpadmin:    The bot stops running and also stops all the bots created from this master channel
        #helpadmin:    You can use this command only if you are an admin user and you are on the master channel
        #helpadmin:
      when /^exit\sbot\s*$/i, /^quit\sbot\s*$/i, /^close\sbot\s*$/i
        if ON_MASTER_BOT
          if ADMIN_USERS.include?(from) #admin user
            unless @questions.keys.include?(from)
              ask("are you sure?", command, from, dest)
            else
              case @questions[from]
              when /yes/i, /yep/i, /sure/i
                respond "Game over!", dest
                respond "Ciao #{display_name}!", dest
                @bots_created.each { |key, value|
                  value[:thread] = ""
                  send_msg_channel(key, "Bot has been closed by #{from}")
                  sleep 0.5
                }
                update_bots_file()
                sleep 0.5
                exit!
              when /no/i, /nope/i, /cancel/i
                @questions.delete(from)
                respond "Thanks, I'm happy to be alive", dest
              else
                respond "I don't understand", dest
                ask("are you sure do you want me to close? (yes or no)", "quit bot", from, dest)
              end
            end
          else
            respond "Only admin users can kill me", dest
          end
        else
          respond "To do this you need to be an admin user in the master channel: <##{@channels_id[MASTER_CHANNEL]}>", dest
        end

        #helpadmin: ----------------------------------------------
        #helpadmin: `start bot`
        #helpadmin: `start this bot`
        #helpadmin:    the bot will start to listen
        #helpadmin:    You can use this command only if you are an admin user
        #helpadmin:
      when /^start\s(this\s)?bot$/i
        if ADMIN_USERS.include?(from) #admin user
          respond "This bot is running and listening from now on. You can pause again: pause this bot", dest
          @status = :on
          unless ON_MASTER_BOT
            send_msg_channel MASTER_CHANNEL, "Changed status on #{CHANNEL} to :on"
          end
        else
          respond "Only admin users can change my status", dest
        end

        #helpadmin: ----------------------------------------------
        #helpadmin: `pause bot`
        #helpadmin: `pause this bot`
        #helpadmin:    the bot will pause so it will listen only to admin commands
        #helpadmin:    You can use this command only if you are an admin user
        #helpadmin:
      when /^pause\s(this\s)?bot$/i
        if ADMIN_USERS.include?(from) #admin user
          respond "This bot is paused from now on. You can start it again: start this bot", dest
          respond "zZzzzzZzzzzZZZZZZzzzzzzzz", dest
          @status = :paused
          unless ON_MASTER_BOT
            send_msg_channel MASTER_CHANNEL, "Changed status on #{CHANNEL} to :paused"
          end
        else
          respond "Only admin users can put me on pause", dest
        end

        #helpadmin: ----------------------------------------------
        #helpadmin: `bot status`
        #helpadmin:    Displays the status of the bot
        #helpadmin:    If on master channel and admin user also it will display info about bots created
        #helpadmin:
      when /^bot\sstatus/i
        get_bots_created()
        gems_remote = `gem list slack-smart-bot --remote`
        version_remote = gems_remote.to_s().scan(/slack-smart-bot \((\d+\.\d+\.\d+)/).join
        version_message = ""
        if version_remote != VERSION
          version_message = " There is a new available version: #{version_remote}."
        end
        respond "Status: #{@status}. Version: #{VERSION}.#{version_message} Rules file: #{File.basename RULES_FILE} ", dest
        if @status == :on
          respond "I'm listening to [#{@listening.join(", ")}]", dest
          if ON_MASTER_BOT and ADMIN_USERS.include?(from)
            
            @bots_created.each do |k,v|
                msg = []
                msg << "`#{v[:channel_name]}` (#{k}):"
                msg << "\tcreator: #{v[:creator_name]}"
                msg << "\tadmins: #{v[:admins]}"
                msg << "\tstatus: #{v[:status]}"
                msg << "\tcreated: #{v[:created]}"
                msg << "\trules: #{v[:rules_file]}"
                msg << "\textended: #{v[:extended]}"
                msg << "\tcloud: #{v[:cloud]}"
                if  ON_MASTER_BOT and v.key?(:cloud) and v[:cloud]
                    msg << "\trunner: `ruby #{$0} \"#{v[:channel_name]}\" \"#{v[:admins]}\" \"#{v[:rules_file]}\" on&`"
                end
                respond msg.join("\n"), dest
            end
          end
        end

        #helpmaster: ----------------------------------------------
        #helpmaster: `notify MESSAGE`
        #helpmaster: `notify all MESSAGE`
        #helpmaster:    It will send a notificaiton message to all bot channels
        #helpmaster:    It will send a notification message to all channels the bot joined and private conversations with the bot
        #helpmaster:    Only works if you are on Master channel and you are an admin user
        #helpmaster:
      when /^notify\s+(all)?\s*(.+)\s*$/i
        if ON_MASTER_BOT
          if ADMIN_USERS.include?(from) #admin user
            all = $1
            message = $2
            if all.nil?
              @bots_created.each do |k, v|
                respond message, k
              end
              respond "Bot channels have been notified", dest
            else
              myconv = client.web_client.users_conversations(exclude_archived: true, limit: 100, types: "im, public_channel").channels
              myconv.each do |c|
                respond message, c.id unless c.name == MASTER_CHANNEL
              end
              respond "Channels and users have been notified", dest
            end
          end
        end

        #helpmaster: ----------------------------------------------
        #helpmaster: `create bot on CHANNEL_NAME`
        #helpmaster: `create cloud bot on CHANNEL_NAME`
        #helpmaster:    creates a new bot on the channel specified
        #helpmaster:    it will work only if you are on Master channel
        #helpmaster:    the admins will be the master admins, the creator of the bot and the creator of the channel
        #helpmaster:    follow the instructions in case creating cloud bots
      when /^create\s+(cloud\s+)?bot\s+on\s+<#C\w+\|(.+)>\s*/i, /^create\s+(cloud\s+)?bot\s+on\s+(.+)\s*/i
        if ON_MASTER_BOT
          cloud = !$1.nil?
          channel = $2

          get_channels_name_and_id() unless @channels_name.keys.include?(channel) or @channels_id.keys.include?(channel)
          channel_id = nil
          if @channels_name.key?(channel) #it is an id
            channel_id = channel
            channel = @channels_name[channel_id]
          elsif @channels_id.key?(channel) #it is a channel name
            channel_id = @channels_id[channel]
          end
          #todo: add pagination for case more than 1000 channels on the workspace
          channels = client.web_client.conversations_list(
            types: 'private_channel,public_channel', 
            limit: '1000',
            exclude_archived: 'true').channels
          channel_found = channels.detect { |c| c.name == channel }
          members = client.web_client.conversations_members(channel: @channels_id[channel]).members unless channel_found.nil?

          if channel_id.nil?
            respond "There is no channel with that name: #{channel}, please be sure is written exactly the same", dest
          elsif channel == MASTER_CHANNEL
            respond "There is already a bot in this channel: #{channel}", dest
          elsif @bots_created.keys.include?(channel_id)
            respond "There is already a bot in this channel: #{channel}, kill it before", dest
          elsif config[:nick_id] != channel_found.creator and !members.include?(config[:nick_id])
            respond "You need to add first to the channel the smart bot user: #{config[:nick]}", dest
          else
            if channel_id != config[:channel]
              begin
                rules_file = "slack-smart-bot_rules_#{channel_id}_#{from.gsub(" ", "_")}.rb"
                if defined?(RULES_FOLDER)
                  rules_file = RULES_FOLDER + rules_file
                else
                  Dir.mkdir("rules") unless Dir.exist?("rules")
                  Dir.mkdir("rules/#{channel_id}") unless Dir.exist?("rules/#{channel_id}")
                  rules_file = "./rules/#{channel_id}/" + rules_file
                end
                default_rules = (__FILE__).gsub(/\.rb$/, "_rules.rb")
                File.delete(rules_file) if File.exist?(rules_file)
                FileUtils.copy_file(default_rules, rules_file) unless File.exist?(rules_file)
                admin_users = Array.new()
                creator_info = client.web_client.users_info(user: channel_found.creator)
                admin_users = [from, creator_info.user.name] + MASTER_USERS
                admin_users.uniq!
                @logger.info "ruby #{$0} \"#{channel}\" \"#{admin_users.join(",")}\" \"#{rules_file}\" on"
                if cloud
                  respond "Copy the bot folder to your cloud location and run `ruby #{$0} \"#{channel}\" \"#{admin_users.join(",")}\" \"#{rules_file}\" on&`", dest
                else
                  t = Thread.new do
                    `ruby #{$0} \"#{channel}\" \"#{admin_users.join(",")}\" \"#{rules_file}\" on`
                  end
                end
                @bots_created[channel_id] = {
                  creator_name: from,
                  channel_id: channel_id,
                  channel_name: @channels_name[channel_id],
                  status: :on,
                  created: Time.now.strftime("%Y-%m-%dT%H:%M:%S.000Z")[0..18],
                  rules_file: rules_file,
                  admins: admin_users.join(","),
                  extended: [],
                  cloud: cloud,
                  thread: t,
                }
                respond "The bot has been created on channel: #{channel}. Rules file: #{File.basename rules_file}. Admins: #{admin_users.join(", ")}", dest
                update_bots_file()
              rescue Exception => stack
                @logger.fatal stack
                message = "Problem creating the bot on channel #{channel}. Error: <#{stack}>."
                @logger.error message
                respond message, dest
              end
            else
              respond "There is already a bot in this channel: #{channel}, and it is the Master Channel!", dest
            end
          end
        else
          @logger.info MASTER_CHANNEL
          @logger.info @channel_id.inspect
          respond "Sorry I cannot create bots from this channel, please visit the master channel: <##{@channels_id[MASTER_CHANNEL]}>", dest
        end

        #helpmaster: ----------------------------------------------
        #helpmaster: `kill bot on CHANNEL_NAME`
        #helpmaster:    kills the bot on the specified channel
        #helpmaster:    Only works if you are on Master channel and you created that bot or you are an admin user
        #helpmaster:
      when /^kill\sbot\son\s<#C\w+\|(.+)>\s*$/i, /^kill\sbot\son\s(.+)\s*$/i
        if ON_MASTER_BOT
          channel = $1

          get_channels_name_and_id() unless @channels_name.keys.include?(channel) or @channels_id.keys.include?(channel)
          channel_id = nil
          if @channels_name.key?(channel) #it is an id
            channel_id = channel
            channel = @channels_name[channel_id]
          elsif @channels_id.key?(channel) #it is a channel name
            channel_id = @channels_id[channel]
          end
          if channel_id.nil?
            respond "There is no channel with that name: #{channel}, please be sure is written exactly the same", dest
          elsif @bots_created.keys.include?(channel_id)
            if @bots_created[channel_id][:admins].split(",").include?(from)
              if @bots_created[channel_id][:thread].kind_of?(Thread) and @bots_created[channel_id][:thread].alive?
                @bots_created[channel_id][:thread].kill
              end
              @bots_created.delete(channel_id)
              update_bots_file()
              respond "Bot on channel: #{channel}, has been killed and deleted.", dest
              send_msg_channel(channel, "Bot has been killed by #{from}")
            else
              respond "You need to be the creator or an admin of that bot channel", dest
            end
          else
            respond "There is no bot in this channel: #{channel}", dest
          end
        else
          respond "Sorry I cannot kill bots from this channel, please visit the master channel: <##{@channels_id[MASTER_CHANNEL]}>", dest
        end



      else
        processed = false
      end
    else
      processed = false
    end

    on_demand = false
    if command.match(/^@?(#{config[:nick]}):*\s+(.+)/im) or
       command.match(/^()!(.+)/im) or
       command.match(/^()<@#{config[:nick_id]}>\s+(.+)/im)
      command = $2
      on_demand = true
    end

    #only when :on and (listening or on demand or direct message)
    if @status == :on and
       (@questions.keys.include?(from) or
        (@listening.include?(from) and typem!=:on_extended) or
        typem == :on_dm or typem ==:on_pg or on_demand)
      processed2 = true

      #help: ===================================
      #help:
      #help: *These commands will run only when the smart bot is listening to you or on demand or in a private conversation with the Smart Bot*. To run a command on demand:
      #help:       `!THE_COMMAND`
      #help:       `@NAME_OF_BOT THE_COMMAND`
      #help:       `NAME_OF_BOT THE_COMMAND`
      #help:
      case command

      when /^bot\s+rules$/i
        if typem == :on_extended or typem == :on_call #for the other cases above.
          help_message_rules = ''
          message = "-\n\n\n===================================\n*Rules from channel <##{@channels_id[CHANNEL]}>*\n"
          if typem == :on_extended
            message += "To run the commands on this extended channel, add `!` before the command.\n"
          end
          help_message_rules = IO.readlines(rules_file).join
          message += help_message_rules.scan(/#\s*help\s*:(.*)/).join("\n")
          respond message, dest
          unless rules_file.empty?
            begin
              eval(File.new(rules_file).read) if File.exist?(rules_file)
            end
          end
          if defined?(git_project) and git_project.to_s!='' and help_message_rules != ''
            respond "Git project: #{git_project}", dest
          else
            def git_project() '' end
            def project_folder() '' end
          end
        end



      #helpadmin: ----------------------------------------------
      #helpadmin: `extend rules to CHANNEL_NAME`
      #helpadmin: `use rules on CHANNEL_NAME`
      #helpadmin:    It will allow to use the specific rules from this channel on the CHANNEL_NAME
      #helpadmin:
      when /^extend\s+rules\s+(to\s+)<#C\w+\|(.+)>/i, /^extend\s+rules\s+(to\s+)(.+)/i, 
        /^use\s+rules\s+(on\s+)<#C\w+\|(.+)>/i, /^use\s+rules\s+(on\s+)(.+)/i 
        unless typem == :on_extended
          if ON_MASTER_BOT
            respond "You cannot use the rules from Master Channel on any other channel.", dest
          elsif !ADMIN_USERS.include?(from) #not admin 
            respond "Only admins can extend the rules. Admins on this channel: #{ADMIN_USERS}", dest
          else
            channel = $2
            #todo: add pagination for case more than 1000 channels on the workspace
            channels = client.web_client.conversations_list(
              types: 'private_channel,public_channel', 
              limit: '1000',
              exclude_archived: 'true').channels
  
            channel_found = channels.detect { |c| c.name == channel }
            members = client.web_client.conversations_members(channel: @channels_id[channel]).members unless channel_found.nil?
            get_bots_created()
            channels_in_use = []
            @bots_created.each do |k,v| 
              if v.key?(:extended) and v[:extended].include?(channel)
                channels_in_use << v[:channel_name]
              end
            end
            
            if channel_found.nil?
              respond "The channel you specified doesn't exist", dest
            elsif @bots_created.key?(@channels_id[channel])
              respond "There is a bot already running on that channel.", dest
            elsif @bots_created[@channels_id[CHANNEL]][:extended].include?(channel)
              respond "The rules are already extended to that channel.", dest
            elsif !members.include?(config[:nick_id])
              respond "You need to add first to the channel the smart bot user: #{config[:nick]}", dest
            elsif !members.include?(user.id)
              respond "You need to join that channel first", dest
            else
              channels_in_use.each do |channel_in_use|
                respond "The rules from channel <##{@channels_id[channel_in_use]}> are already in use on that channel", dest
              end
              @bots_created[@channels_id[CHANNEL]][:extended] = [] unless @bots_created[@channels_id[CHANNEL]].key?(:extended)
              @bots_created[@channels_id[CHANNEL]][:extended] << channel
              update_bots_file()
              respond "Now the rules from <##{@channels_id[CHANNEL]}> are available on <##{@channels_id[channel]}>", dest
              respond "<@#{user.id}> extended the rules from <##{@channels_id[CHANNEL]}> to this channel so now you can talk to the Smart Bot on demand using those rules.", @channels_id[channel]
              respond "Use `!` before the command you want to run", @channels_id[channel]
              respond "To see the specific rules for this bot on this channel: `!bot rules`", @channels_id[channel]
            end
          end
        end

        #helpadmin: ----------------------------------------------
        #helpadmin: `stop using rules on CHANNEL_NAME`
        #helpadmin:    it will stop using the extended rules on the specified channel.
        #helpadmin:
      when /^stop using rules (on\s+)<#C\w+\|(.+)>/i, /^stop using rules (on\s+)(.+)/i
        unless typem == :on_extended
          if !ADMIN_USERS.include?(from) #not admin 
            respond "Only admins can extend or stop using the rules. Admins on this channel: #{ADMIN_USERS}", dest
          else
            channel = $2
            get_bots_created()
            if @bots_created[@channels_id[CHANNEL]][:extended].include?(channel)
              @bots_created[@channels_id[CHANNEL]][:extended].delete(channel)
              update_bots_file()
              respond "The rules won't be accessible from <##{@channels_id[CHANNEL]}> from now on.", dest
              respond "<@#{user.id}> removed the access to the rules of <##{@channels_id[CHANNEL]}> from this channel.", @channels_id[channel]
            else
              respond "The rules were not accessible from <##{@channels_id[channel]}>", dest
            end
          end
        end

      #help: ----------------------------------------------
      #help: `add shortcut NAME: COMMAND`
      #help: `add sc NAME: COMMAND`
      #help: `add shortcut for all NAME: COMMAND`
      #help: `add sc for all NAME: COMMAND`
      #help: `shortchut NAME: COMMAND`
      #help: `shortchut for all NAME: COMMAND`
      #help:    It will add a shortcut that will execute the command we supply.
      #help:    In case we supply 'for all' then the shorcut will be available for everybody
      #help:    Example:
      #help:        _add shortcut for all Spanish account: code require 'iso/iban'; 10.times {puts ISO::IBAN.random('ES')}_
      #help:    Then to call this shortcut:
      #help:        _sc spanish account_
      #help:        _shortcut Spanish Account_
      #help:        _Spanish Account_
      #help:
      when /^(add\s)?shortcut\s(for\sall)?\s*(.+)\s*:\s*(.+)/i, /^(add\s)sc\s(for\sall)?\s*(.+)\s*:\s*(.+)/i
        unless typem == :on_extended
          for_all = $2
          shortcut_name = $3.to_s.downcase
          command_to_run = $4
          @shortcuts[from] = Hash.new() unless @shortcuts.keys.include?(from)

          if !ADMIN_USERS.include?(from) and @shortcuts[:all].include?(shortcut_name) and !@shortcuts[from].include?(shortcut_name)
            respond "Only the creator of the shortcut or an admin user can modify it", dest
          elsif !@shortcuts[from].include?(shortcut_name)
            #new shortcut
            @shortcuts[from][shortcut_name] = command_to_run
            @shortcuts[:all][shortcut_name] = command_to_run if for_all.to_s != ""
            update_shortcuts_file()
            respond "shortcut added", dest
          else

            #are you sure? to avoid overwriting existing
            unless @questions.keys.include?(from)
              ask("The shortcut already exists, are you sure you want to overwrite it?", command, from, dest)
            else
              case @questions[from]
              when /^(yes|yep)/i
                @shortcuts[from][shortcut_name] = command_to_run
                @shortcuts[:all][shortcut_name] = command_to_run if for_all.to_s != ""
                update_shortcuts_file()
                respond "shortcut added", dest
                @questions.delete(from)
              when /^no/i
                respond "ok, I won't add it", dest
                @questions.delete(from)
              else
                respond "I don't understand, yes or no?", dest
              end
            end
          end
        end

        #help: ----------------------------------------------
        #help: `delete shortcut NAME`
        #help: `delete sc NAME`
        #help:    It will delete the shortcut with the supplied name
        #help:
      when /^delete\s+shortcut\s+(.+)/i, /^delete\s+sc\s+(.+)/i
        unless typem == :on_extended
          shortcut = $1.to_s.downcase
          deleted = false

          if !ADMIN_USERS.include?(from) and @shortcuts[:all].include?(shortcut) and !@shortcuts[from].include?(shortcut)
            respond "Only the creator of the shortcut or an admin user can delete it", dest
          elsif (@shortcuts.keys.include?(from) and @shortcuts[from].keys.include?(shortcut)) or
                (ADMIN_USERS.include?(from) and @shortcuts[:all].include?(shortcut))
            #are you sure? to avoid deleting by mistake
            unless @questions.keys.include?(from)
              ask("are you sure you want to delete it?", command, from, dest)
            else
              case @questions[from]
              when /^(yes|yep)/i
                respond "shortcut deleted!", dest
                respond "#{shortcut}: #{@shortcuts[from][shortcut]}", dest
                @shortcuts[from].delete(shortcut)
                @shortcuts[:all].delete(shortcut)
                @questions.delete(from)
                update_shortcuts_file()
              when /^no/i
                respond "ok, I won't delete it", dest
                @questions.delete(from)
              else
                respond "I don't understand, yes or no?", dest
              end
            end
          else
            respond "shortcut not found", dest
          end
        end

        #help: ----------------------------------------------
        #help: `see shortcuts`
        #help: `see sc`
        #help:    It will display the shortcuts stored for the user and for :all
        #help:
      when /^see\sshortcuts/i, /^see\ssc/i
        unless typem == :on_extended
          msg = ""
          if @shortcuts[:all].keys.size > 0
            msg = "*Available shortcuts for all:*\n"
            @shortcuts[:all].each { |name, value|
              msg += "    _#{name}: #{value}_\n"
            }
            respond msg, dest
          end

          if @shortcuts.keys.include?(from) and @shortcuts[from].keys.size > 0
            new_hash = @shortcuts[from].dup
            @shortcuts[:all].keys.each { |k| new_hash.delete(k) }
            if new_hash.keys.size > 0
              msg = "*Available shortcuts for #{from}:*\n"
              new_hash.each { |name, value|
                msg += "    _#{name}: #{value}_\n"
              }
              respond msg, dest
            end
          end
          respond "No shortcuts found", dest if msg == ""
        end

        #help: ----------------------------------------------
        #help: `id channel CHANNEL_NAME`
        #help:    shows the id of a channel name
        #help:
      when /^id\schannel\s<#C\w+\|(.+)>\s*/i, /^id channel (.+)/
        unless typem == :on_extended
          channel_name = $1
          get_channels_name_and_id()
          if @channels_id.keys.include?(channel_name)
            respond "the id of #{channel_name} is #{@channels_id[channel_name]}", dest
          else
            respond "channel: #{channel_name} not found", dest
          end
        end

        #help: ----------------------------------------------
        #help: `ruby RUBY_CODE`
        #help: `code RUBY_CODE`
        #help:     runs the code supplied and returns the output. Also you can send a Ruby file instead. Examples:
        #help:       _code puts (34344/99)*(34+14)_
        #help:       _ruby require 'json'; res=[]; 20.times {res<<rand(100)}; my_json={result: res}; puts my_json.to_json_
        #help:
      when /^\s*ruby\s(.+)/im, /^\s*code\s(.+)/im
        code = $1
        code.gsub!("\\n", "\n")
        code.gsub!("\\r", "\r")
        @logger.info code
        unless code.match?(/System/i) or code.match?(/Kernel/i) or code.include?("File") or
               code.include?("`") or code.include?("exec") or code.include?("spawn") or code.include?("IO.") or
               code.match?(/open3/i) or code.match?(/bundle/i) or code.match?(/gemfile/i) or code.include?("%x") or
               code.include?("ENV") or code.match?(/=\s*IO/)
          unless rules_file.empty?
            begin
              eval(File.new(rules_file).read) if File.exist?(rules_file)
            end
          end

          respond "Running", dest if code.size > 100

          begin
            code.gsub!(/^\W*$/,'') #to remove special chars from slack when copy/pasting
            ruby = "ruby -e \"#{code.gsub('"', '\"')}\""
            if defined?(project_folder) and project_folder.to_s!='' and Dir.exist?(project_folder)
              ruby = ("cd #{project_folder} &&" + ruby)
            else
              def project_folder() '' end
            end
            stdout, stderr, status = Open3.capture3(ruby)
            if stderr == ""
              if stdout == ""
                respond "Nothing returned. Remember you need to use p or puts to print", dest
              else
                respond stdout, dest
              end
            else
              respond stderr, dest
            end
          rescue Exception => exc
            respond exc, dest
          end
        else
          respond "Sorry I cannot run this due security reasons", dest
        end


      else
        processed2 = false
      end #of case

      processed = true if processed or processed2
    end

    return processed
  end

  def respond(msg, dest = nil)
    if dest.nil?
      client.message(channel: @channels_id[CHANNEL], text: msg, as_user: true)
    elsif dest[0] == "C" or dest[0] == "G" # channel
      client.message(channel: dest, text: msg, as_user: true)
    elsif dest[0] == "D" # Direct message
      send_msg_user(dest, msg)
    else
      @logger.warn("method respond not treated correctly: msg:#{msg} dest:#{dest}")
    end
  end

  #context: previous message
  #to: user that should answer
  def ask(question, context, to, dest = nil)
    if dest.nil?
      client.message(channel: @channels_id[CHANNEL], text: "#{to}: #{question}", as_user: true)
    elsif dest[0] == "C" or dest[0] == "G" # channel
      client.message(channel: dest, text: "#{to}: #{question}", as_user: true)
    elsif dest[0] == "D" #private message
      send_msg_user(dest, "#{to}: #{question}")
    end
    @questions[to] = context
  end

  # to: (String) Channel name or id
  # msg: (String) message to send
  def send_msg_channel(to, msg)
    unless msg == ""
      get_channels_name_and_id() unless @channels_name.key?(to) or @channels_id.key?(to)
      if @channels_name.key?(to) #it is an id
        channel_id = to
      elsif @channels_id.key?(to) #it is a channel name
        channel_id = @channels_id[to]
      else
        @logger.fatal "Channel: #{to} not found. Message: #{msg}"
      end
      client.message(channel: channel_id, text: msg, as_user: true)
    end
  end

  #to send messages without listening for a response to users
  def send_msg_user(id_user, msg)
    unless msg == ""
      if id_user[0] == "D"
        client.message(channel: id_user, as_user: true, text: msg)
      else
        im = client.web_client.im_open(user: id_user)
        client.message(channel: im["channel"]["id"], as_user: true, text: msg)
      end
    end
  end

  #to send a file to an user or channel
  #send_file(dest, 'the message', "#{project_folder}/temp/logs_ptBI.log", 'message to be sent', 'text/plain', "text")
  #send_file(dest, 'the message', "#{project_folder}/temp/example.jpeg", 'message to be sent', 'image/jpeg', "jpg")
  def send_file(to, msg, file, title, format, type = "text")
    if to[0] == "U" #user
      im = client.web_client.im_open(user: to)
      channel = im["channel"]["id"]
    else
      channel = to
    end

    client.web_client.files_upload(
      channels: channel,
      as_user: true,
      file: Faraday::UploadIO.new(file, format),
      title: title,
      filename: file,
      filetype: type,
      initial_comment: msg,
    )
  end

  private :update_bots_file, :get_bots_created, :get_channels_name_and_id, :update_shortcuts_file
end
