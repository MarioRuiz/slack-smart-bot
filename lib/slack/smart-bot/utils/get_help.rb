class SlackSmartBot
  def get_help(rules_file, dest, from, only_rules = false)
    order = {
      general: [:hi_bot, :bye_bot, :bot_help, :bot_status, :use_rules, :stop_using_rules],
      on_bot: [:ruby_code, :repl, :get_repl, :run_repl, :delete_repl, :see_repls, :add_shortcut, :delete_shortcut, :see_shortcuts],
      on_bot_admin: [:extend_rules, :stop_using_rules_on, :start_bot, :pause_bot, :add_routine,
        :see_routines, :start_routine, :pause_routine, :remove_routine, :run_routine]
    }
    # user_type: :admin, :user, :admin_master
    if config.masters.include?(from)
      user_type = :admin_master
    elsif config.admins.include?(from)
      user_type = :admin
    else
      user_type = :user
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

    @help_messages ||= build_help("#{__dir__}/../commands")
    if only_rules
      help = {}
    else
      help = @help_messages.deep_copy
    end
    if rules_file != ""
      help[:rules_file] = ''
      help[:rules_file] += IO.readlines(config.path+rules_file).join.scan(/#\s*help\s*\w*:(.*)/i).join("\n") + "\n"
      if File.exist?(config.path+'/rules/general_rules.rb')
        help[:rules_file] += IO.readlines(config.path+'/rules/general_rules.rb').join.scan(/#\s*help\s*\w*:(.*)/i).join("\n")
      end
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
            *NAME_OF_BOT THE_COMMAND*
      To run a command on demand and add the respond on a thread:
            *^THE_COMMAND*
            *!!THE_COMMAND*\n"
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
      txt += help.rules_file
    end

    return txt
  end
end
