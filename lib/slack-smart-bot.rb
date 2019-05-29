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
  VERSION = Gem.loaded_specs.values.select {|x| x.name=='slack-smart-bot'}[0].version
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
    if ON_MASTER_BOT and File.exist?("./rules/rules_imported.rb")
      file_conf = IO.readlines("./rules/rules_imported.rb").join
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
      respond "Smart Bot started v#{VERSION}\nIf you want to know what I can do for you: `bot help`.\n`bot rules` if you want to display just the specific rules of this channel.\nYou can talk to me privately if you prefer it."
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
  #help:    The only 
  def listen
    @salutations = [config[:nick], config[:nick_id], "bot", "smart"]
    client.on :message do |data|
      if data.channel[0] == 'D' or data.channel[0] == "C" #Direct message or Channel
         dest = data.channel
      else # not treated
        dest = nil
      end
      #todo: sometimes data.user is nil, check the problem.
      @logger.warn "!dest is nil. user: #{data.user}, channel: #{data.channel}, message: #{data.text}" if dest.nil?
      # Direct messages are treated only on the master bot
      @logger.info dest.inspect
      @logger.info data.text
      if !dest.nil? and ((dest[0] == 'D' and ON_MASTER_BOT) or (dest[0] == 'C'))
        user_info = wclient.users_info(user: data.user)
        #todo: check to remove user_info.user.name == config[:nick] since I think we will never get messages from the bot on slack
        # if Direct message or we are in the channel of the bot
        if dest[0]=='D' or @channels_id[CHANNEL] == data.channel or user_info.user.name == config[:nick]
          res = process_first(user_info.user, data.text, dest, data.channel)
          next if res.to_s == "next"
        # if @botname on #channel_rules: do something
        elsif data.text.match(/^<@#{config[:nick_id]}>\s(on\s)?<#(\w+)\|(.+)>\s*:?\s*(.+)$/i)
          channel_rules = $2
          channel_rules_name = $3
          command = $4
          command = "!" + command unless command[0]=="!"
          
          if @channels_id[CHANNEL] == channel_rules #to be treated only on the bot of the requested channel
            dest = data.channel
            channels = wclient.channels_list.channels
            channel_found = channels.detect { |c| c.name == channel_rules_name }
            if channel_found.nil?
              @logger.fatal "Not possible to find the channel #{channel_rules_name}"
            elsif channel_found.name == MASTER_CHANNEL
              respond "You cannot use the rules from Master Channel on any other channel.", dest
            elsif user_info.user.id == channel_found.creator or channel_found.members.include?(user_info.user.id)
              res = process_first(user_info.user, command, dest, channel_rules)
              next if res.to_s == "next"
            else
              respond "You need to join the channel <##{channel_found.id}> to be able to use the rules.", dest
            end
          end
        elsif @questions.keys.include?(user_info.user.name)
          dest = data.channel
          res = process_first(user_info.user, data.text, dest, @channels_id[CHANNEL])
          next if res.to_s == "next"
        end
      end
    end

    @logger.info "Bot listening"
    client.start!
  end

  def process_first(user, text, dest, dchannel)
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
        respond "Shortcut not found", dest
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
          processed = process(user, command, dest, dchannel)
          @logger.info "command: #{nick}> #{command}" if processed
          on_demand = false
          if command.match(/^@?(#{config[:nick]}):*\s+(.+)$/i) or
             command.match(/^()!(.+)$/i) or
             command.match(/^()<@#{config[:nick_id]}>\s+(.+)$/i)
            command = $2
            on_demand = true
          end
          if @status == :on and
             (@questions.keys.include?(nick) or
              @listening.include?(nick) or
              dest[0]=='D' or on_demand)
            @logger.info "command: #{nick}> #{command}" unless processed
            #todo: verify this
            if dest[0]=='C' #only for channels, not for DM
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
                rules(user, command, processed, dest)
              else
                @logger.warn "It seems like rules method is not defined"
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
  def process(user, command, dest, dchannel)
    from = user.name
    firstname = from.split(/ /).first
    processed = true

    case command

    #help: ----------------------------------------------
    #help: `Hello Bot`
    #help: `Hello Smart`
    #help: `Hello THE_NAME_OF_THE_BOT`
    #help:    Also apart of Hello you can use _Hallo, Hi, Hola, What's up, Hey, Hæ_
    #help:    Bot starts listening to you
    #help:
    when /^(Hello|Hallo|Hi|Hola|What's\sup|Hey|Hæ)\s(#{@salutations.join("|")})\s*$/i
      if @status == :on
        greetings = ["Hello", "Hallo", "Hi", "Hola", "What's up", "Hey", "Hæ"].sample
        respond "#{greetings} #{firstname}", dest
        if @rules_imported.key?(user.id) and @rules_imported[user.id].key?(user.id) and dest[0]=='D'
          respond "You are using specific rules for channel: <##{@rules_imported[user.id][user.id]}>", dest
        elsif @rules_imported.key?(user.id) and @rules_imported[user.id].key?(dchannel) and dest[0]=='C'
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
        respond "#{bye} #{firstname}", dest
        @listening.delete(from)
      end

      #helpadmin: ----------------------------------------------
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
            ask("are you sure?", command, from, dest)
          else
            case @questions[from]
            when /yes/i, /yep/i, /sure/i
              respond "Game over!", dest
              respond "Ciao #{firstname}!", dest
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
          get_channels_name_and_id() unless @channels_name.keys.include?(MASTER_CHANNEL) and @channels_name.keys.include?(CHANNEL)
          send_msg_channel @channels_name[MASTER_CHANNEL], "Changed status on #{@channels_name[CHANNEL]} to :on"
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
          get_channels_name_and_id() unless @channels_name.keys.include?(MASTER_CHANNEL) and @channels_name.keys.include?(CHANNEL)
          send_msg_channel @channels_name[MASTER_CHANNEL], "Changed status on #{@channels_name[CHANNEL]} to :paused"
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
      respond "Status: #{@status}. Version: #{VERSION}. Rules file: #{File.basename RULES_FILE} ", dest
      if @status == :on
        respond "I'm listening to [#{@listening.join(", ")}]", dest
        if ON_MASTER_BOT and ADMIN_USERS.include?(from)
          @bots_created.each { |key, value|
            respond "#{key}: #{value}", dest
          }
        end
      end

      #helpmaster: ----------------------------------------------
      #helpmaster: `create bot on CHANNEL_NAME`
      #helpmaster:    creates a new bot on the channel specified
      #helpmaster:    it will work only if you are on Master channel
      #helpmaster:
    when /^create\sbot\son\s<#C\w+\|(.+)>\s*/i, /^create\sbot\son\s(.+)\s*/i
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
          respond "There is no channel with that name: #{channel}, please be sure is written exactly the same", dest
        elsif channel == MASTER_CHANNEL
          respond "There is already a bot in this channel: #{channel}", dest
        elsif @bots_created.keys.include?(channel_id)
          respond "There is already a bot in this channel: #{channel}, kill it before", dest
        elsif config[:nick_id] != channel_found.creator and !channel_found.members.include?(config[:nick_id])
          respond "You need to add first to the channel the smart bot user: #{config[:nick]}, kill it before", dest
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
              respond "The bot has been created on channel: #{channel}. Rules file: #{File.basename rules_file}", dest
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

      #help: ----------------------------------------------
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
        respond "The channel you are trying to use doesn't exist", dest
      elsif channel_found.name == MASTER_CHANNEL
        respond "You cannot use the rules from Master Channel on any other channel.", dest
      else
        if user.id == channel_found.creator or channel_found.members.include?(user.id)
          @rules_imported[user.id] = {} unless @rules_imported.key?(user.id)
          if dest[0]=="C" #todo: take in consideration bots that are not master
            @rules_imported[user.id][dchannel] = channel_found.id
          else
            @rules_imported[user.id][user.id] = channel_found.id
          end
          update_rules_imported() if ON_MASTER_BOT
          respond "I'm using now the rules from <##{channel_found.id}>", dest
        else
          respond "You need to join the channel <##{channel_found.id}> to be able to use the rules.", dest
        end
      end

      #help: ----------------------------------------------
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
      if dest[0]=='C' #channel
        if @rules_imported.key?(user.id) and @rules_imported[user.id].key?(dchannel)
          if @rules_imported[user.id][dchannel] != channel_id
            respond "You are not using those rules.", dest
          else
            @rules_imported[user.id].delete(dchannel)
            update_rules_imported() if ON_MASTER_BOT
            respond "You won't be using those rules from now on.", dest
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
          end
        else
          respond "You were not using those rules.", dest
        end
      end

      #help: ----------------------------------------------
      #help: `bot help`
      #help: `bot what can I do?`
      #help: `bot rules`
      #help:    it will display this help
      #help:    `bot rules` will show only the specific rules for this channel.
    when /^bot (rules|help)/i, /^bot,? what can I do/i
      if $1.to_s.match?(/rules/i)
        specific = true
      else
        specific = false
      end
      if !specific
        help_message = IO.readlines(__FILE__).join
        if ADMIN_USERS.include?(from) #admin user
          respond "*Commands for administrators:*\n#{help_message.scan(/#\s*help\s*admin:(.*)/).join("\n")}", dest
        end
        if ON_MASTER_BOT and dest[0]=="C"
          respond "*Commands only on Master Channel <##{@channels_id[MASTER_CHANNEL]}>:*\n#{help_message.scan(/#\s*help\s*master:(.*)/).join("\n")}", dest
        end
        respond help_message.scan(/#\s*help\s*:(.*)/).join("\n"), dest
      end
      if dest[0]=="C" # on a channel
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
            respond "*You are using rules from another channel: <##{@rules_imported[user.id][dchannel]}>. These are the specific commands for that channel:*", dest
          end
        end
        help_message_rules = IO.readlines(rules_file).join
        respond help_message_rules.scan(/#\s*help\s*:(.*)/).join("\n"), dest
      elsif dest[0]=='D' and @rules_imported.key?(user.id) and @rules_imported[user.id].key?(user.id) #direct message
        unless @bots_created.key?(@rules_imported[user.id][user.id])
          file_conf = IO.readlines($0.gsub(".rb", "_bots.rb")).join
          unless file_conf.to_s() == ""
            @bots_created = eval(file_conf)
          end
        end
        if @bots_created.key?(@rules_imported[user.id][user.id])
          rules_file = @bots_created[@rules_imported[user.id][user.id]][:rules_file]
          respond "*You are using rules from channel: <##{@rules_imported[user.id][user.id]}>. These are the specific commands for that channel:*", dest
          help_message_rules = IO.readlines(rules_file).join
          respond help_message_rules.scan(/#\s*help\s*:(.*)/).join("\n"), dest
        end
      end
      respond "Github project: https://github.com/MarioRuiz/slack-smart-bot", dest if !specific
    else
      processed = false
    end

    on_demand = false
    if command.match(/^@?(#{config[:nick]}):*\s+(.+)$/i) or
       command.match(/^()!(.+)$/i) or
       command.match(/^()<@#{config[:nick_id]}>\s+(.+)$/i)
      command = $2
      on_demand = true
    end

    #only when :on and (listening or on demand or direct message)
    if @status == :on and
       (@questions.keys.include?(from) or
        @listening.include?(from) or
        dest[0]=='D' or on_demand)
      processed2 = true

      #help: ===================================
      #help:
      #help: *These commands will run only when the smart bot is listening to you or on demand or in a private conversation with the Smart Bot*. To run a command on demand:
      #help:       `!THE_COMMAND`
      #help:       `@NAME_OF_BOT THE_COMMAND`
      #help:       `NAME_OF_BOT THE_COMMAND`
      #help:
      case command

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
      #help:
      when /^(add\s)?shortcut\s(for\sall)?\s*(.+):\s(.+)/i, /^(add\s)sc\s(for\sall)?\s*(.+):\s(.+)/i
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

        #help: ----------------------------------------------
        #help: `delete shortcut NAME`
        #help: `delete sc NAME`
        #help:    It will delete the shortcut with the supplied name
        #help:
      when /^delete\sshortcut\s(.+)/i, /^delete\ssc\s(.+)/i
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

        #help: ----------------------------------------------
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

        #help: ----------------------------------------------
        #help: `id channel CHANNEL_NAME`
        #help:    shows the id of a channel name
        #help:
      when /^id\schannel\s<#C\w+\|(.+)>\s*/i, /^id channel (.+)/
        channel_name = $1
        get_channels_name_and_id()
        if @channels_id.keys.include?(channel_name)
          respond "the id of #{channel_name} is #{@channels_id[channel_name]}", dest
        else
          respond "channel: #{channel_name} not found", dest
        end

        #help: ----------------------------------------------
        #help: `ruby RUBY_CODE`
        #help: `code RUBY_CODE`
        #help:     runs the code supplied and returns the output. Examples:
        #help:       _code puts (34344/99)*(34+14)_
        #help:       _ruby require 'json'; res=[]; 20.times {res<<rand(100)}; my_json={result: res}; puts my_json.to_json_
        #help:
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
          respond "Sorry I cannot run this due security issues", dest
        end
      else
        processed2 = false
      end
      processed = true if processed or processed2
    end

    return processed
  end

  def respond(msg, dest = nil)
    if dest.nil?
      client.message(channel: @channels_id[CHANNEL], text: msg, as_user: true)
    elsif dest[0]=="C" # channel
      client.message(channel: dest, text: msg, as_user: true)      
    elsif dest[0]=='D' # Direct message
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
    elsif dest[0]=="C" # channel
      client.message(channel: dest, text: "#{to}: #{question}", as_user: true)    
    elsif dest[0]=='D' #private message
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
      if id_user[0]=="D"
        client.message(channel: id_user, as_user: true, text: msg)
      else
        im = wclient.im_open(user: id_user)
        client.message(channel: im["channel"]["id"], as_user: true, text: msg)
      end
    end
  end

  #to send a file to an user or channel
  def send_file(to, msg, file, title, format)
    if to[0] == "U" #user
      im = wclient.im_open(user: to)
      channel = im["channel"]["id"]
    else
      channel = to
    end

    wclient.files_upload(
      channels: channel,
      as_user: true,
      file: Faraday::UploadIO.new(file, format),
      title: title,
      filename: file,
      initial_comment: msg,
    )
  end

  private :update_bots_file, :get_channels_name_and_id, :update_shortcuts_file
end
