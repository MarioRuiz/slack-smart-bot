require "slack-ruby-client"
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
  attr_accessor :config, :client, :wclient

  def initialize(config)
    Dir.mkdir("./logs") unless Dir.exist?("./logs")
    Dir.mkdir("./shortcuts") unless Dir.exist?("./shortcuts")
    logfile = File.basename(RULES_FILE.gsub("_rules_", "_logs_"), ".rb") + ".log"
    @logger = Logger.new("./logs/#{logfile}")
    config_log = config.dup
    config_log.delete(:token)
    @logger.info "Initializing bot: #{config_log.inspect}"

    config[:channel] = CHANNEL
    self.config = config

    Slack.configure do |conf|
      conf.token = config[:token]
    end
    self.wclient = Slack::Web::Client.new
    self.client = Slack::RealTime::Client.new

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
      file_conf = IO.readlines($0.gsub(".rb", "_bots.rb")).join
      unless file_conf.to_s() == ""
        @bots_created = eval(file_conf)
        if @bots_created.kind_of?(Hash)
          @bots_created.each { |key, value|
            @logger.info "ruby #{$0} \"#{value[:channel_name]}\" \"#{value[:admins]}\" \"#{value[:rules_file]}\" #{value[:status].to_sym}"
            t = Thread.new do
              `ruby #{$0} \"#{value[:channel_name]}\" \"#{value[:admins]}\" \"#{value[:rules_file]}\" #{value[:status].to_sym}`
            end
            value[:thread] = t
          }
        end
      end
    end

    # rules imported only for private channels
    if ON_MASTER_BOT and File.exist?('./rules/rules_imported.rb')
      file_conf = IO.readlines('./rules/rules_imported.rb').join
      unless file_conf.to_s() == ""
        @rules_imported = eval(file_conf)
      end
    end
    wclient.auth_test

    begin
      user_info = wclient.users_info(user: "#{"@" if config[:nick][0] != "@"}#{config[:nick]}")
      config[:nick_id] = user_info.user.id
    rescue Exception => stack
      @logger.fatal stack
      abort("The bot user specified on settings: #{config[:nick]}, doesn't exist on Slack. Execution aborted")
    end

    client.on :hello do
      m = "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."
      puts m
      @logger.info m
      respond "Smart Bot started\nIf you want to know what I can do for you: `bot help` or `bot specific help`\nYou can send me also a direct message."
    end

    @status = STATUS_INIT
    @questions = Hash.new()
    @channels_id = Hash.new()
    @channels_name = Hash.new()
    get_channels_name_and_id()
    self
  end

  def update_bots_file
    file = File.open($0.gsub(".rb", "_bots.rb"), "w")
    bots_created = @bots_created.dup
    bots_created.each { |k, v| v[:thread] = "" }
    file.write bots_created.inspect
    file.close
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
    channels = wclient.channels_list.channels
    @channels_id = Hash.new()
    @channels_name = Hash.new()
    channels.each do |ch|
      unless ch.is_archived
        @channels_id[ch.name] = ch.id
        @channels_name[ch.id] = ch.name
      end
    end
  end

  def listen
    @salutations = [config[:nick], config[:nick_id], "bot", "smart"]
    client.on :message do |data|
      if data.channel[0] == "D" #Direct message
        id_user = data.user
      else
        id_user = nil
      end
      # Direct messages are treated only on the master bot
      if id_user.nil? or (!id_user.nil? and ON_MASTER_BOT)
        #todo: sometimes data.user is nil, check the problem.
        if data.user.nil?
          @logger.fatal "user is nil. channel: #{data.channel}, message: #{data.text}"
        else
          user_info = wclient.users_info(user: data.user)
          if !id_user.nil? or @channels_id[CHANNEL] == data.channel or user_info.user.name == config[:nick]
            res = process_first(user_info.user, data.text, id_user, data.channel)
            next if res.to_s == "next"
          end
        end
      end
    end

    @logger.info "Bot listening"
    client.start!
  end

  def process_first(user, text, id_user, dchannel)
    nick = user.name
    #todo: verify if on slack on anytime nick == config[:nick]
    if nick == config[:nick] or nick == (config[:nick] + " · Bot") #if message is coming from the bot
      begin
        @logger.info "#{nick}: #{text}"
        case text
        when /^Bot has been killed by/
          exit!
        when /^Changed status on (.+) to :(.+)/i
          channel = $1
          status = $2
          #todo: channel should be channel_id
          @bots_created[channel][:status] = status.to_sym
          update_bots_file()
        end
        return :next #don't continue analyzing
      rescue Exception => stack
        @logger.fatal stack
        return :next
      end
    end

    if text.match?(/^!?(shortcut|sc)\s(.+)/i)
      shortcut = text.scan(/!?\w+\s*(.+)\s*/i).join.downcase
      if text[0] == "!"
        addexcl = true
      else
        addexcl = false
      end
      if @shortcuts.keys.include?(nick) and @shortcuts[nick].keys.include?(shortcut)
        text = @shortcuts[nick][shortcut].dup
      elsif @shortcuts.keys.include?(:all) and @shortcuts[:all].keys.include?(shortcut)
        text = @shortcuts[:all][shortcut].dup
      else
        respond "Shortcut not found", id_user
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
          processed = process(user, command, id_user, dchannel)
          @logger.info "command: #{nick}> #{command}" if processed
          if @status == :on and
             ((@questions.keys.include?(nick) or
               @listening.include?(nick) or
               !id_user.nil? or
               command.match?(/^@?#{@salutations.join("|")}:*\s+(.+)$/i) or
               command.match?(/^<@#{@salutations.join("|")}>\s+(.+)$/i) or
               command.match?(/^!(.+)$/)))
            @logger.info "command: #{nick}> #{command}" unless processed
            #todo: verify this
            if id_user.nil? #only for channels, not for DM
              rules_file = RULES_FILE
              if @rules_imported.key?(user.id) and @rules_imported[user.id].key?(dchannel)
                unless @bots_created.key?(@rules_imported[user.id][dchannel])
                  file_conf = IO.readlines($0.gsub(".rb", "_bots.rb")).join
                  unless file_conf.to_s() == ""
                    @bots_created = eval(file_conf)
                  end
                end
                if @bots_created.key?(@rules_imported[user.id][dchannel])
                  rules_file = @bots_created[@rules_imported[user.id][dchannel]][:rules_file]
                end
              end
              @logger.info "rules file: #{rules_file}"
              begin
                eval(File.new(rules_file).read) if File.exist?(rules_file)
              rescue Exception => stack
                @logger.fatal "ERROR ON RULES FILE: #{rules_file}"
                @logger.fatal stack
              end
              if defined?(rules)
                command[0] = "" if command[0] == "!"
                command.gsub!(/^@\w+:*\s*/, "")
                rules(user, command, processed, id_user)
              else
                @logger.warn "It seems like rules method is not defined"
              end
            elsif @rules_imported.key?(user.id) and @rules_imported[user.id].key?(user.id)
              unless @bots_created.key?(@rules_imported[user.id][user.id])
                file_conf = IO.readlines($0.gsub(".rb", "_bots.rb")).join
                unless file_conf.to_s() == ""
                  @bots_created = eval(file_conf)
                end
              end

              if @bots_created.key?(@rules_imported[user.id][user.id])
                rules_file = @bots_created[@rules_imported[user.id][user.id]][:rules_file]
                begin
                  eval(File.new(rules_file).read) if File.exist?(rules_file)
                rescue Exception => stack
                  @logger.fatal "ERROR ON imported RULES FILE: #{rules_file}"
                  @logger.fatal stack
                end
              end

              if defined?(rules)
                command[0] = "" if command[0] == "!"
                command.gsub!(/^@\w+:*\s*/, "")
                rules(user, command, processed, id_user)
              else
                @logger.warn "It seems like rules method is not defined"
              end
            else #jal9
              @logger.info "it is a direct message with no rules file selected so no rules file executed."
              unless processed
                resp = %w{ what huh sorry }.sample
                respond "#{resp}?", id_user
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

  #help:
  #help: *General commands:*:
  #help:
  def process(user, command, id_user, dchannel)
    from = user.name
    firstname = from.split(/ /).first
    processed = true

    case command

    #help: `Hello Bot`
    #help: `Hello Smart`
    #help: `Hello THE_NAME_OF_THE_BOT`
    #help: Also apart of Hello you can use _Hallo, Hi, Hola, What's up, Hey, Hæ_
    #help:    Bot starts listening to you
    #help:
    when /^(Hello|Hallo|Hi|Hola|What's\sup|Hey|Hæ)\s(#{@salutations.join("|")})\s*$/i
      if @status == :on
        greetings = ["Hello", "Hallo", "Hi", "Hola", "What's up", "Hey", "Hæ"].sample
        respond "#{greetings} #{firstname}", id_user
        if @rules_imported.key?(user.id) and @rules_imported[user.id].key?(user.id) and !id_user.nil?
          respond "You are using specific rules for channel: <##{@rules_imported[user.id][user.id]}>", id_user
        elsif @rules_imported.key?(user.id) and @rules_imported[user.id].key?(dchannel) and id_user.nil?
          respond "You are using specific rules for channel: <##{@rules_imported[user.id][dchannel]}>", id_user
        end
        @listening << from unless @listening.include?(from)
      end

      #help: `Bye Bot`
      #help: `Bye Smart`
      #help: `Bye NAME_OF_THE_BOT`
      #help: Also apart of Bye you can use _Bæ, Good Bye, Adiós, Ciao, Bless, Bless Bless, Adeu_
      #help:    Bot stops listening to you
      #help:
    when /^(Bye|Bæ|Good\sBye|Adiós|Ciao|Bless|Bless\sBless|Adeu)\s(#{@salutations.join("|")})\s*$/i
      if @status == :on
        bye = ["Bye", "Bæ", "Good Bye", "Adiós", "Ciao", "Bless", "Bless bless", "Adeu"].sample
        respond "#{bye} #{firstname}", id_user
        @listening.delete(from)
      end

      #helpadmin: `exit bot`
      #helpadmin: `quit bot`
      #helpadmin: `close bot`
      #helpadmin:    The bot stops running and also stops all the bots created from this master channel
      #helpadmin:    You can use this command only if you are an admin user and you are on the master channel
      #helpadmin:
    when /^exit\sbot/i, /^quit\sbot/i, /^close\sbot/i
      if ON_MASTER_BOT
        if ADMIN_USERS.include?(from) #admin user
          unless @questions.keys.include?(from)
            ask("are you sure?", command, from, id_user)
          else
            case @questions[from]
            when /yes/i, /yep/i, /sure/i
              respond "Game over!", id_user
              respond "Ciao #{firstname}!", id_user
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
              respond "Thanks, I'm happy to be alive", id_user
            else
              respond "I don't understand", id_user
              ask("are you sure do you want me to close? (yes or no)", "quit bot", from, id_user)
            end
          end
        else
          respond "Only admin users can kill me", id_user
        end
      else
        respond "To do this you need to be an admin user in the master channel: <##{@channels_id[MASTER_CHANNEL]}>", id_user
      end

      #helpadmin: `start bot`
      #helpadmin: `start this bot`
      #helpadmin:    the bot will start to listen
      #helpadmin:    You can use this command only if you are an admin user
      #helpadmin:
    when /^start\s(this\s)?bot$/i
      if ADMIN_USERS.include?(from) #admin user
        respond "This bot is running and listening from now on. You can pause again: pause this bot", id_user
        @status = :on
        unless ON_MASTER_BOT
          get_channels_name_and_id() unless @channels_name.keys.include?(MASTER_CHANNEL) and @channels_name.keys.include?(CHANNEL)
          send_msg_channel @channels_name[MASTER_CHANNEL], "Changed status on #{@channels_name[CHANNEL]} to :on"
        end
      else
        respond "Only admin users can change my status", id_user
      end

      #helpadmin: `pause bot`
      #helpadmin: `pause this bot`
      #helpadmin:    the bot will pause so it will listen only to admin commands
      #helpadmin:    You can use this command only if you are an admin user
      #helpadmin:
    when /^pause\s(this\s)?bot$/i
      if ADMIN_USERS.include?(from) #admin user
        respond "This bot is paused from now on. You can start it again: start this bot", id_user
        respond "zZzzzzZzzzzZZZZZZzzzzzzzz", id_user
        @status = :paused
        unless ON_MASTER_BOT
          get_channels_name_and_id() unless @channels_name.keys.include?(MASTER_CHANNEL) and @channels_name.keys.include?(CHANNEL)
          send_msg_channel @channels_name[MASTER_CHANNEL], "Changed status on #{@channels_name[CHANNEL]} to :paused"
        end
      else
        respond "Only admin users can put me on pause", id_user
      end

      #helpadmin: `bot status`
      #helpadmin:    Displays the status of the bot
      #helpadmin:    If on master channel and admin user also it will display info about bots created
      #helpadmin:
    when /^bot\sstatus/i
      respond "Status: #{@status}. Rules file: #{File.basename RULES_FILE} ", id_user
      if @status == :on
        respond "I'm listening to [#{@listening.join(", ")}]", id_user
        if ON_MASTER_BOT and ADMIN_USERS.include?(from)
          @bots_created.each { |key, value|
            respond "#{key}: #{value}", id_user
          }
        end
      end

      #helpmaster: `create bot on CHANNEL_NAME`
      #helpmaster:    creates a new bot on the channel specified
      #helpmaster:    it will work only if you are on Master channel
      #helpmaster:
    when /^create\sbot\son\s<#C\w+\|(.+)>\s*/i, /^create\sbot\son\s(.+)\s*/i #jal9
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
        channels = wclient.channels_list.channels
        channel_found = channels.detect { |c| c.name == channel }
  
        if channel_id.nil?
          respond "There is no channel with that name: #{channel}, please be sure is written exactly the same", id_user
        elsif channel == MASTER_CHANNEL
          respond "There is already a bot in this channel: #{channel}", id_user
        elsif @bots_created.keys.include?(channel_id) #jal9
          respond "There is already a bot in this channel: #{channel}, kill it before", id_user
        elsif config[:nick_id] != channel_found.creator and !channel_found.members.include?(config[:nick_id])
          respond "You need to add first to the channel the smart bot user: #{config[:nick]}, kill it before", id_user
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
              admin_users = [from] + MASTER_USERS
              admin_users.uniq!
              @logger.info "ruby #{$0} \"#{channel}\" \"#{admin_users.join(",")}\" \"#{rules_file}\" on"
              t = Thread.new do
                `ruby #{$0} \"#{channel}\" \"#{admin_users.join(",")}\" \"#{rules_file}\" on`
              end
              @bots_created[channel_id] = {
                creator_name: from,
                channel_id: channel_id,
                channel_name: @channels_name[channel_id],
                status: :on,
                created: Time.now.strftime("%Y-%m-%dT%H:%M:%S.000Z")[0..18],
                rules_file: rules_file,
                admins: admin_users.join(","),
                thread: t,
              }
              respond "The bot has been created on channel: #{channel}. Rules file: #{File.basename rules_file}", id_user
              update_bots_file()
            rescue Exception => stack
              @logger.fatal stack
              message = "Problem creating the bot on channel #{channel}. Error: <#{stack}>."
              @logger.error message
              respond message, id_user
            end
          else
            respond "There is already a bot in this channel: #{channel}, and it is the Master Channel!", id_user
          end
        end
      else
        @logger.info MASTER_CHANNEL
        @logger.info @channel_id.inspect
        respond "Sorry I cannot create bots from this channel, please visit the master channel: <##{@channels_id[MASTER_CHANNEL]}>", id_user
      end

      #helpmaster: `kill bot on CHANNEL_NAME`
      #helpmaster:    kills the bot on the specified channel
      #helpmaster:    Only works if you are on Master channel and you created that bot or you are an admin user
      #helpmaster:
    when /^kill\sbot\son\s<#C\w+\|(.+)>\s*/i, /^kill\sbot\son\s(.+)\s*/i
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
          respond "There is no channel with that name: #{channel}, please be sure is written exactly the same", id_user
        elsif @bots_created.keys.include?(channel_id)
          if @bots_created[channel_id][:admins].split(",").include?(from)
            if @bots_created[channel_id][:thread].kind_of?(Thread) and @bots_created[channel_id][:thread].alive?
              @bots_created[channel_id][:thread].kill
            end
            @bots_created.delete(channel_id)
            update_bots_file()
            respond "Bot on channel: #{channel}, has been killed and deleted.", id_user
            send_msg_channel(channel, "Bot has been killed by #{from}")
          else
            respond "You need to be the creator or an admin of that channel", id_user
          end
        else
          respond "There is no bot in this channel: #{channel}", id_user
        end
      else
        respond "Sorry I cannot kill bots from this channel, please visit the master channel: <##{@channels_id[MASTER_CHANNEL]}>", id_user
      end

      #help: `use rules from CHANNEL`
      #help: `use rules CHANNEL`
      #help:    it will use the rules from the specified channel.
      #help:    you need to be part of that channel to be able to use the rules.
      #help:
    when /^use rules (from\s+)?<#C\w+\|(.+)>/i, /^use rules (from\s+)?(.+)/i
      channel = $2
      channels = wclient.channels_list.channels
      channel_found = channels.detect { |c| c.name == channel }
      if channel_found.nil?
        respond "The channel you are trying to use doesn't exist", id_user
      elsif channel_found.name == MASTER_CHANNEL
        respond "You cannot use the rules from Master Channel on any other channel.", id_user
      else
        if user.id == channel_found.creator or channel_found.members.include?(user.id)
          @rules_imported[user.id] = {} unless @rules_imported.key?(user.id)
          if id_user.nil? #todo: take in consideration bots that are not master
            @rules_imported[user.id][dchannel] = channel_found.id
          else
            @rules_imported[user.id][user.id] = channel_found.id
          end
          update_rules_imported() if ON_MASTER_BOT
          respond "I'm using now the rules from <##{channel_found.id}>", id_user
        else
          respond "You need to join the channel <##{channel_found.id}> to be able to use the rules.", id_user
        end
      end

      #help: `stop using rules from CHANNEL`
      #help: `stop using rules CHANNEL`
      #help:    it will stop using the rules from the specified channel.
      #help:
    when /^stop using rules (from\s+)?<#C\w+\|(.+)>/i, /^stop using rules (from\s+)?(.+)/i
      channel = $2
      if @channels_id.key?(channel)
        channel_id = @channels_id[channel]
      else
        channel_id = channel
      end
      if id_user.nil? #channel
        if @rules_imported.key?(user.id) and @rules_imported[user.id].key?(dchannel)
          if @rules_imported[user.id][dchannel]!= channel_id
            respond "You are not using those rules.", id_user
          else
            @rules_imported[user.id].delete(dchannel)
            update_rules_imported() if ON_MASTER_BOT
            respond "You won't be using those rules from now on.", id_user
          end
        else
          respond "You were not using those rules.", id_user
        end
      else #direct message
        if @rules_imported.key?(user.id) and @rules_imported[user.id].key?(user.id)
          if @rules_imported[user.id][user.id]!= channel_id
            respond "You are not using those rules.", id_user
          else
            @rules_imported[user.id].delete(user.id)
            update_rules_imported() if ON_MASTER_BOT
            respond "You won't be using those rules from now on.", id_user
          end
        else
          respond "You were not using those rules.", id_user
        end
      end


      #help: `bot help`
      #help: `bot what can I do?`
      #help: `bot specific help`
      #help:    it will display this help
      #help:    bot specific help will show only the specific rules for this channel.
    when /^bot (specific\s)?help/i, /^bot,? what can I do/i
      if $1.to_s != ''
        specific = true
      else
        specific = false
      end
      if !specific then
        help_message = IO.readlines(__FILE__).join
        if ADMIN_USERS.include?(from) #admin user
          respond "*Commands for administrators:*\n#{help_message.scan(/#\s*help\s*admin:(.*)/).join("\n")}", id_user
        end
        if ON_MASTER_BOT and id_user.nil?
          respond "*Commands only on Master Channel <##{@channels_id[MASTER_CHANNEL]}>:*\n#{help_message.scan(/#\s*help\s*master:(.*)/).join("\n")}", id_user
        end
        respond help_message.scan(/#\s*help\s*:(.*)/).join("\n"), id_user
      end
      if id_user.nil? # on a channel
        rules_file = RULES_FILE

        if @rules_imported.key?(user.id) and @rules_imported[user.id].key?(dchannel)

          unless @bots_created.key?(@rules_imported[user.id][dchannel])
            file_conf = IO.readlines($0.gsub(".rb", "_bots.rb")).join
            unless file_conf.to_s() == ""
              @bots_created = eval(file_conf)
            end
          end
          if @bots_created.key?(@rules_imported[user.id][dchannel])
            rules_file = @bots_created[@rules_imported[user.id][dchannel]][:rules_file]
            respond  "*You are using rules from another channel: <##{@rules_imported[user.id][dchannel]}>. These are the specific commands for that channel:*", id_user
          end
        end
        help_message_rules = IO.readlines(rules_file).join
        respond help_message_rules.scan(/#\s*help\s*:(.*)/).join("\n"), id_user
      elsif !id_user.nil? and @rules_imported.key?(user.id) and @rules_imported[user.id].key?(user.id) #direct message
        unless @bots_created.key?(@rules_imported[user.id][user.id])
          file_conf = IO.readlines($0.gsub(".rb", "_bots.rb")).join
          unless file_conf.to_s() == ""
            @bots_created = eval(file_conf)
          end
        end
        if @bots_created.key?(@rules_imported[user.id][user.id])
          rules_file = @bots_created[@rules_imported[user.id][user.id]][:rules_file]
          respond  "*You are using rules from channel: <##{@rules_imported[user.id][user.id]}>. These are the specific commands for that channel:*", id_user
          help_message_rules = IO.readlines(rules_file).join
          respond help_message_rules.scan(/#\s*help\s*:(.*)/).join("\n"), id_user
        end
      end
      respond "Github project: https://github.com/MarioRuiz/slack-smart-bot", id_user
    else
      processed = false
    end

    #only when :on and (listening or on demand or direct message)
    if @status == :on and
       ((@questions.keys.include?(from) or
         @listening.include?(from) or
         !id_user.nil? or
         command.match?(/^@?#{@salutations.join("|")}:*\s+(.+)$/i) or
         command.match?(/^!(.+)$/)))
      processed2 = true

      # help:
      # help: *These commands will run only when the smart bot is listening to you or on demand*. On demand examples:
      # help:       `!THE_COMMAND`
      # help:       `@bot THE_COMMAND`
      # help:       `@NAME_OF_BOT THE_COMMAND`
      # help:       `NAME_OF_BOT THE_COMMAND`
      # help:
      case command

      #help: `add shortcut NAME: COMMAND`
      #help: `add sc NAME: COMMAND`
      #help: `add shortcut for all NAME: COMMAND`
      #help: `add sc for all NAME: COMMAND`
      #help: `shortchut NAME: COMMAND`
      #help: `shortchut for all NAME: COMMAND`
      #help:    It will add a shortcut that will execute the command we supply.
      #help:    In case we supply 'for all' then the shorcut will be available for everybody
      #help:    Example:
      #help:        `add shortcut for all Spanish account: code require 'iso/iban'; 10.times {puts ISO::IBAN.random('ES')}`
      #help:    Then to call this shortcut:
      #help:        `sc spanish account`
      #help:        `shortcut Spanish Account`
      #help:
      when /^(add\s)?shortcut\s(for\sall)?\s*(.+):\s(.+)/i, /^(add\s)sc\s(for\sall)?\s*(.+):\s(.+)/i
        for_all = $2
        shortcut_name = $3.to_s.downcase
        command_to_run = $4
        @shortcuts[from] = Hash.new() unless @shortcuts.keys.include?(from)

        if !ADMIN_USERS.include?(from) and @shortcuts[:all].include?(shortcut_name) and !@shortcuts[from].include?(shortcut_name)
          respond "Only the creator of the shortcut or an admin user can modify it", id_user
        elsif !@shortcuts[from].include?(shortcut_name)
          #new shortcut
          @shortcuts[from][shortcut_name] = command_to_run
          @shortcuts[:all][shortcut_name] = command_to_run if for_all.to_s != ""
          update_shortcuts_file()
          respond "shortcut added", id_user
        else

          #are you sure? to avoid overwriting existing
          unless @questions.keys.include?(from)
            ask("The shortcut already exists, are you sure you want to overwrite it?", command, from, id_user)
          else
            case @questions[from]
            when /^(yes|yep)/i
              @shortcuts[from][shortcut_name] = command_to_run
              @shortcuts[:all][shortcut_name] = command_to_run if for_all.to_s != ""
              update_shortcuts_file()
              respond "shortcut added", id_user
              @questions.delete(from)
            when /^no/i
              respond "ok, I won't add it", id_user
              @questions.delete(from)
            else
              respond "I don't understand, yes or no?", id_user
            end
          end
        end

        #help: `delete shortcut NAME`
        #help: `delete sc NAME`
        #help:    It will delete the shortcut with the supplied name
        #help:
      when /^delete\sshortcut\s(.+)/i, /^delete\ssc\s(.+)/i
        shortcut = $1.to_s.downcase
        deleted = false

        if !ADMIN_USERS.include?(from) and @shortcuts[:all].include?(shortcut) and !@shortcuts[from].include?(shortcut)
          respond "Only the creator of the shortcut or an admin user can delete it", id_user
        elsif (@shortcuts.keys.include?(from) and @shortcuts[from].keys.include?(shortcut)) or
              (ADMIN_USERS.include?(from) and @shortcuts[:all].include?(shortcut))
          #are you sure? to avoid deleting by mistake
          unless @questions.keys.include?(from)
            ask("are you sure you want to delete it?", command, from, id_user)
          else
            case @questions[from]
            when /^(yes|yep)/i
              respond "shortcut deleted!", id_user
              respond "#{shortcut}: #{@shortcuts[from][shortcut]}", id_user
              @shortcuts[from].delete(shortcut)
              @shortcuts[:all].delete(shortcut)
              @questions.delete(from)
              update_shortcuts_file()
            when /^no/i
              respond "ok, I won't delete it", id_user
              @questions.delete(from)
            else
              respond "I don't understand, yes or no?", id_user
            end
          end
        else
          respond "shortcut not found", id_user
        end

        #help: `see shortcuts`
        #help: `see sc`
        #help:    It will display the shortcuts stored for the user and for :all
        #help:
      when /^see\sshortcuts/i, /^see\ssc/i
        msg = ""
        if @shortcuts[:all].keys.size > 0
          msg = "*Available shortcuts for all:*\n"
          @shortcuts[:all].each { |name, value|
            msg += "    _#{name}: #{value}_\n"
          }
          respond msg, id_user
        end

        if @shortcuts.keys.include?(from) and @shortcuts[from].keys.size > 0
          new_hash = @shortcuts[from].dup
          @shortcuts[:all].keys.each { |k| new_hash.delete(k) }
          if new_hash.keys.size > 0
            msg = "*Available shortcuts for #{from}:*\n"
            new_hash.each { |name, value|
              msg += "    _#{name}: #{value}_\n"
            }
            respond msg, id_user
          end
        end
        respond "No shortcuts found", id_user if msg == ""

        #help: `id channel CHANNEL_NAME`
        #help:    shows the id of a channel name
        #help:
      when /^id\schannel\s<#C\w+\|(.+)>\s*/i, /^id channel (.+)/
        channel_name = $1
        get_channels_name_and_id()
        if @channels_id.keys.include?(channel_name)
          respond "the id of #{channel_name} is #{@channels_id[channel_name]}", id_user
        else
          respond "channel: #{channel_name} not found", id_user
        end

        # help: `ruby RUBY_CODE`
        # help: `code RUBY_CODE`
        # help:     runs the code supplied and returns the output. Examples:
        # help:       `code puts (34344/99)*(34+14)`
        # help:       `ruby require 'json'; res=[]; 20.times {res<<rand(100)}; my_json={result: res}; puts my_json.to_json`
        # help:
      when /^ruby\s(.+)/im, /code\s(.+)/im
        code = $1
        code.gsub!("\\n", "\n")
        unless code.match?(/System/i) or code.match?(/Kernel/i) or code.include?("File") or
               code.include?("`") or code.include?("exec") or code.include?("spawn") or code.include?("IO") or
               code.match?(/open3/i) or code.match?(/bundle/i) or code.match?(/gemfile/i) or code.include?("%x") or
               code.include?("ENV")
          begin
            stdout, stderr, status = Open3.capture3("ruby -e \"#{code.gsub('"', '\"')}\"")
            if stderr == ""
              if stdout == ""
                respond "Nothing returned. Remember you need to use p or puts to print", id_user
              else
                respond stdout, id_user
              end
            else
              respond stderr, id_user
            end
          rescue Exception => exc
            respond exc, id_user
          end
        else
          respond "Sorry I cannot run this due security issues", id_user
        end
      else
        processed2 = false
      end
      processed = true if processed or processed2
    end

    return processed
  end

  def respond(msg, id_user = nil)
    if id_user.nil?
      client.message(channel: @channels_id[CHANNEL], text: msg, as_user: true)
    else #private message
      send_msg_user(id_user, msg)
    end
  end

  #context: previous message
  #to: user that should answer
  def ask(question, context, to, id_user = nil)
    if id_user.nil?
      client.message(channel: @channels_id[CHANNEL], text: "#{to}: #{question}", as_user: true)
    else #private message
      send_msg_user(id_user, "#{to}: #{question}")
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
      im = wclient.im_open(user: id_user)
      client.message(channel: im["channel"]["id"], as_user: true, text: msg)
    end
  end

  private :update_bots_file, :get_channels_name_and_id, :update_shortcuts_file
end
