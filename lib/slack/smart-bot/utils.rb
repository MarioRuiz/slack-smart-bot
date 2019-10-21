class SlackSmartBot
  def update_bots_file
    file = File.open($0.gsub(".rb", "_bots.rb"), "w")
    bots_created = @bots_created.dup
    bots_created.each { |k, v| v[:thread] = "" }
    file.write bots_created.inspect
    file.close
  end

  def get_bots_created
    if File.exist?($0.gsub(".rb", "_bots.rb"))
      if !defined?(@datetime_bots_created) or @datetime_bots_created != File.mtime($0.gsub(".rb", "_bots.rb"))
        file_conf = IO.readlines($0.gsub(".rb", "_bots.rb")).join
        if file_conf.to_s() == ""
          @bots_created = {}
        else
          @bots_created = eval(file_conf)
        end
        @datetime_bots_created = File.mtime($0.gsub(".rb", "_bots.rb"))
        @bots_created.each do |k, v| # to be compatible with old versions
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
      types: "private_channel,public_channel",
      limit: "1000",
      exclude_archived: "true",
    ).channels

    @channels_id = Hash.new()
    @channels_name = Hash.new()
    channels.each do |ch|
      unless ch.is_archived
        @channels_id[ch.name] = ch.id
        @channels_name[ch.id] = ch.name
      end
    end
  end

  def get_routines(channel = @channel_id)
    if File.exist?("./routines/routines_#{channel}.rb")
      file_conf = IO.readlines("./routines/routines_#{channel}.rb").join
      unless file_conf.to_s() == ""
        @routines = eval(file_conf)
      end
    end
  end

  def update_routines(channel = @channel_id)
    file = File.open("./routines/routines_#{channel}.rb", "w")
    file.write (@routines.inspect)
    file.close
  end

  def create_routine_thread(name)
    t = Thread.new do
      while @routines.key?(@channel_id) and @routines[@channel_id].key?(name)
        started = Time.now
        if @status == :on and @routines[@channel_id][name][:status] == :on
          if @routines[@channel_id][name][:file_path].match?(/\.rb$/i)
            ruby = "ruby "
          else
            ruby = ""
          end
          if @routines[@channel_id][name][:at] == "" or
             (@routines[@channel_id][name][:at] != "" and @routines[@channel_id][name][:running] and
              @routines[@channel_id][name][:next_run] != "" and Time.now.to_s >= @routines[@channel_id][name][:next_run])
            if @routines[@channel_id][name][:file_path] != ""
              process_to_run = "#{ruby}#{Dir.pwd}#{@routines[@channel_id][name][:file_path][1..-1]}"
              process_to_run = ("cd #{project_folder} &&" + process_to_run) if defined?(project_folder)

              stdout, stderr, status = Open3.capture3(process_to_run)
              if stderr == ""
                unless stdout.match?(/\A\s*\z/)
                  respond "routine *`#{name}`*: #{stdout}", @routines[@channel_id][name][:dest]
                end
              else
                respond "routine *`#{name}`*: #{stdout} #{stderr}", @routines[@channel_id][name][:dest]
              end
            else #command
              respond "routine *`#{name}`*: #{@routines[@channel_id][name][:command]}", @routines[@channel_id][name][:dest]
              started = Time.now
              treat_message({ channel: @routines[@channel_id][name][:dest],
                             user: @routines[@channel_id][name][:creator_id],
                             text: @routines[@channel_id][name][:command],
                             files: nil })
            end
            # in case the routine was deleted while running the process
            if !@routines.key?(@channel_id) or !@routines[@channel_id].key?(name)
              Thread.exit
            end
            @routines[@channel_id][name][:last_run] = started.to_s
          end
          if @routines[@channel_id][name][:last_run] == "" and @routines[@channel_id][name][:next_run] != "" #for the first create_routine of one routine with at
            elapsed = 0
            require "time"
            every_in_seconds = Time.parse(@routines[@channel_id][name][:next_run]) - Time.now
          elsif @routines[@channel_id][name][:next_run] == "" and @routines[@channel_id][name][:at] != "" #coming from start after pause for 'at'
            if started.strftime("%k:%M:%S") < @routines[@channel_id][name][:at]
              nt = @routines[@channel_id][name][:at].split(":")
              next_run = Time.new(started.year, started.month, started.day, nt[0], nt[1], nt[2])
            else
              next_run = started + (24 * 60 * 60) # one more day
              nt = @routines[@channel_id][name][:at].split(":")
              next_run = Time.new(next_run.year, next_run.month, next_run.day, nt[0], nt[1], nt[2])
            end
            @routines[@channel_id][name][:next_run] = next_run.to_s
            elapsed = 0
            every_in_seconds = next_run - started
          else
            every_in_seconds = @routines[@channel_id][name][:every_in_seconds]
            elapsed = Time.now - started
            @routines[@channel_id][name][:last_elapsed] = elapsed
            @routines[@channel_id][name][:next_run] = (started + every_in_seconds).to_s
          end
          @routines[@channel_id][name][:running] = true
          @routines[@channel_id][name][:sleeping] = every_in_seconds - elapsed
          update_routines()
          sleep(every_in_seconds - elapsed) unless elapsed > every_in_seconds
        else
          sleep 30
        end
      end
    end
  end

  def build_help(path)
    help_message = {}
    Dir["#{path}/*"].each do |t|
      if Dir.exist?(t)
        help_message[t.scan(/\/(\w+)$/).join.to_sym] = build_help(t)
      else
        help_message[t.scan(/\/(\w+)\.rb$/).join.to_sym] = IO.readlines(t).join.scan(/#\s*help\s*\w*:(.*)/).join("\n")
      end
    end
    return help_message
  end

  def remove_hash_keys(hash, key)
    newh = Hash.new
    hash.each do |k, v|
      unless k == key
        if v.is_a?(String)
          newh[k] = v
        else
          newh[k] = remove_hash_keys(v, key)
        end
      end
    end
    return newh
  end

  def get_help(rules_file, dest, from, only_rules = false)
    order = {
      general: [:hi_bot, :bye_bot, :bot_help, :bot_status, :use_rules, :stop_using_rules],
      on_bot: [:ruby_code, :add_shortcut, :delete_shortcut, :see_shortcuts],
      on_bot_admin: [:extend_rules, :stop_using_rules_on, :start_bot, :pause_bot, :add_routine,
                     :see_routines, :start_routine, :pause_routine, :remove_routine, :run_routine],
    }
    # user_type: :admin, :user, :admin_master
    if MASTER_USERS.include?(from)
      user_type = :admin_master
    elsif ADMIN_USERS.include?(from)
      user_type = :admin
    else
      user_type = :user
    end
    # channel_type: :bot, :master_bot, :direct, :extended, :external
    if dest[0] == "D"
      channel_type = :direct
    elsif ON_MASTER_BOT
      channel_type = :master_bot
    elsif @channel_id != dest
      channel_type = :extended
    else
      channel_type = :bot
    end

    @help_messages ||= build_help("#{__dir__}/commands")
    if only_rules
      help = {}
    else
      help = @help_messages.deep_copy
    end
    if rules_file != ""
      help[:rules_file] = IO.readlines(rules_file).join.scan(/#\s*help\s*\w*:(.*)/i).join("\n")
    end

    help = remove_hash_keys(help, :admin_master) unless user_type == :admin_master
    help = remove_hash_keys(help, :admin) unless user_type == :admin or user_type == :admin_master
    help = remove_hash_keys(help, :on_master) unless channel_type == :master_bot
    help = remove_hash_keys(help, :on_extended) unless channel_type == :extended
    help = remove_hash_keys(help, :on_dm) unless channel_type == :direct
    txt = ""
    if channel_type == :bot or channel_type == :master_bot
      txt += "===================================
      For the Smart Bot start listening to you say *hi bot*
      To run a command on demand even when the Smart Bot is not listening to you:
            *!THE_COMMAND*
            *@NAME_OF_BOT THE_COMMAND*
            *NAME_OF_BOT THE_COMMAND*\n"
    end
    if channel_type == :direct
      txt += "===================================
      When on a private conversation with the Smart Bot, I'm always listening to you.\n"
    end
    unless channel_type == :master_bot or channel_type == :extended
      txt += "===================================
      *Commands from Channels without a bot:*
      ----------------------------------------------
      `@BOT_NAME on #CHANNEL_NAME COMMAND`
      `@BOT_NAME #CHANNEL_NAME COMMAND`
        It will run the supplied command using the rules on the channel supplied.
        You need to join the specified channel to be able to use those rules.
        Also you can use this command to call another bot from a channel with a running bot.

      The commands you will be able to use from a channel without a bot: 
      *bot rules*, *ruby CODE*, *add shortcut NAME: COMMAND*, *delete shortcut NAME*, *see shortcuts*, *shortcut NAME*
      *And all the specific rules of the Channel*\n"
    end

    if help.key?(:general)
      unless channel_type == :direct
        txt += "===================================
        *General commands even when the Smart Bot is not listening to you:*\n"
      end
      order.general.each do |o|
        txt += help.general[o]
      end
      if channel_type == :master_bot
        txt += help.on_master.create_bot
      end
    end

    if help.key?(:on_bot)
      unless channel_type == :direct
        txt += "===================================
        *General commands only when the Smart Bot is listening to you or on demand:*\n"
      end
      order.on_bot.each do |o|
        txt += help.on_bot[o]
      end
    end

    if help.key?(:on_bot) and help.on_bot.key?(:admin)
      txt += "===================================
        *Admin commands:*\n"
      txt += "\n\n"
      order.on_bot_admin.each do |o|
        txt += help.on_bot.admin[o]
      end
      if help.key?(:on_master) and help.on_master.key?(:admin)
        help.on_master.admin.each do |k, v|
          txt += v if v.is_a?(String)
        end
      end
    end

    if help.key?(:on_master) and help.on_master.key?(:admin_master)
      txt += "===================================
      *Master Admin commands:*\n"
      help.on_master.admin_master.each do |k, v|
        txt += v if v.is_a?(String)
      end
    end

    if help.key?(:on_bot) and help.on_bot.key?(:admin_master) and help.on_bot.admin_master.size > 0
      txt += "===================================
      *Master Admin commands:*\n"
    end

    if help.key?(:rules_file)
      @logger.info channel_type
      if channel_type == :extended or channel_type == :direct
        @logger.info help.rules_file
        help.rules_file = help.rules_file.gsub(/^\s*\*These are specific commands.+NAME_OF_BOT THE_COMMAND`\s*$/im, "")
      end
      txt += help.rules_file
    end
    return txt
  end
end
