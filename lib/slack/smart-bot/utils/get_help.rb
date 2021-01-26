class SlackSmartBot
  def get_help(rules_file, dest, from, only_rules, expanded)
    order = {
      general: [:whats_new, :hi_bot, :bye_bot, :bot_help, :bot_status, :use_rules, :stop_using_rules, :bot_stats],
      on_bot: [:ruby_code, :repl, :get_repl, :run_repl, :delete_repl, :see_repls, :add_shortcut, :delete_shortcut, :see_shortcuts],
      on_bot_admin: [:extend_rules, :stop_using_rules_on, :start_bot, :pause_bot, :add_routine,
        :see_routines, :start_routine, :pause_routine, :remove_routine, :run_routine]
    }
    if config.masters.include?(from)
      user_type = :master # master admin
    elsif config.admins.include?(from)
      user_type = :admin
    else
      user_type = :normal #normal user
    end
    # channel_type: :bot, :master_bot, :direct, :extended, :external
    if dest[0] == "D"
      channel_type = :direct
    elsif config.on_master_bot
      channel_type = :master_bot
    elsif @channel_id != dest
      channel_type = :extended
    else
      channel_type = :bot
    end

    @help_messages_expanded ||= build_help("#{__dir__}/../commands", true)
    @help_messages_not_expanded ||= build_help("#{__dir__}/../commands", false)
    if only_rules
      help = {}
    elsif expanded
      help = @help_messages_expanded.deep_copy[user_type]
    else
      help = @help_messages_not_expanded.deep_copy[user_type]
    end

    if rules_file != ""
      help[:rules_file] = build_help(config.path+rules_file, expanded)[user_type].values.join("\n") + "\n"
     
      # to get all the help from other rules files added to the main rules file by using require or load. For example general_rules.rb
      res = IO.readlines(config.path+rules_file).join.scan(/$\s*(load|require)\s("|')(.+)("|')/)
      rules_help = []
      txt = ''
      if res.size>0
        res.each do |r|
          begin
            eval("txt = \"#{r[2]}\"")
            rules_help << txt if File.exist?(txt)
          rescue
          end
        end
      end
      rules_help.each do |rh|
        rhelp = build_help(rh, expanded)
        help[:rules_file] += rhelp[user_type].values.join("\n") + "\n"
      end
    end
    help = remove_hash_keys(help, :admin_master) unless user_type == :master
    help = remove_hash_keys(help, :admin) unless user_type == :admin or user_type == :master
    help = remove_hash_keys(help, :on_master) unless channel_type == :master_bot
    help = remove_hash_keys(help, :on_extended) unless channel_type == :extended
    help = remove_hash_keys(help, :on_dm) unless channel_type == :direct
    txt = ""

    if (channel_type == :bot or channel_type == :master_bot) and expanded
      txt += "===================================
      For the Smart Bot start listening to you say *hi bot*
      To run a command on demand even when the Smart Bot is not listening to you:
            *!THE_COMMAND*
            *@NAME_OF_BOT THE_COMMAND*
            *NAME_OF_BOT THE_COMMAND*
      To run a command on demand and add the respond on a thread:
            *^THE_COMMAND*
            *!!THE_COMMAND*\n"
    end
    if channel_type == :direct and expanded
      txt += "===================================
      When on a private conversation with the Smart Bot, I'm always listening to you.\n"
    end
    unless channel_type == :master_bot or channel_type == :extended or !expanded
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

    if help.key?(:on_bot) and help.on_bot.key?(:admin_master) and help.on_bot.admin_master.size > 0
      txt += "===================================
      *Master Admin commands:*\n"
      help.on_bot.admin_master.each do |k, v|
        txt += v if v.is_a?(String)
      end
    end

    if help.key?(:on_master) and help.on_master.key?(:admin_master) and help.on_master.admin_master.size > 0
      txt += "===================================
      *Master Admin commands:*\n"
      help.on_master.admin_master.each do |k, v|
        txt += v if v.is_a?(String)
      end
    end

    if help.key?(:rules_file)
      @logger.info channel_type if config.testing
      if channel_type == :extended or channel_type == :direct
        @logger.info help.rules_file if config.testing
        help.rules_file = help.rules_file.gsub(/^\s*\*These are specific commands.+NAME_OF_BOT THE_COMMAND`\s*$/im, "")
      end

      unless expanded
        resf = ''
        help.rules_file.split(/^\s*\-+\s*$/).each do |rule|
          command_done = false
          explanation_done = false
          example_done = false
          if rule.match?(/These are specific commands for this/i)
            resf += rule
            resf += "-"*50
            resf += "\n"
          elsif rule.match?(/To run a command on demand and add the respond on a thread/i)
            resf += rule
            resf += "-"*50
            resf += "\n"
          else
            rule.split("\n").each do |line|
              if line.match?(/^\s*\-+\s*/i)
                resf += line
              elsif !command_done and line.match?(/^\s*`.+`\s*/i)
                resf += "\n#{line}"
                command_done = true
              elsif !explanation_done and line.match?(/^\s+[^`].+\s*/i)
                resf += "\n#{line}"
                explanation_done = true
              elsif !example_done and line.match?(/^\s*_.+_\s*/i)
                resf += "\n     Example: #{line}"
                example_done = true
              end
            end
            resf += "\n\n"
          end
        end
        help.rules_file = resf
      end
      txt += help.rules_file
    end

    return txt
  end
end
