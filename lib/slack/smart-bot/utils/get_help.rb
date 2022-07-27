class SlackSmartBot
  def get_help(rules_file, dest, from, only_rules, expanded, descriptions: true, only_normal_user: false)
    order = {
      general: [:bot_help, :hi_bot, :bye_bot, :add_admin, :remove_admin, :see_admins, :poster, :add_announcement, :delete_announcement, 
                :see_announcements, :see_command_ids, :share_messages, :see_shares, :delete_share, :see_favorite_commands, :see_statuses, 
                :allow_access, :see_access, :deny_access, :add_team, :add_memo_team, :delete_memo_team, :set_memo_status, :see_teams, :update_team, :ping_team, :delete_team],
      on_bot_general: [:whats_new, :suggest_command, :bot_status, :use_rules, :stop_using_rules, :bot_stats, :leaderboard],
      on_bot: [:ruby_code, :repl, :get_repl, :run_repl, :delete_repl, :see_repls, :kill_repl, :add_shortcut, :delete_shortcut, :see_shortcuts],
      on_bot_admin: [:extend_rules, :stop_using_rules_on, :start_bot, :pause_bot, :add_routine,
        :see_routines, :start_routine, :pause_routine, :remove_routine, :see_result_routine, :run_routine]
    }
    if config.masters.include?(from)
      user_type = :master # master admin
    elsif is_admin?(from)
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

    if Thread.current[:typem] == :on_pg or Thread.current[:typem] == :on_pub
      channel_type = :external
    end

    if only_normal_user
      user_type = :normal 
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

    help[:general_commands_file] = build_help("#{__dir__}/../commands/general_bot_commands.rb", expanded)[user_type].values.join("\n") + "\n" unless only_rules
    if File.exist?(config.path + '/rules/general_commands.rb') and !only_rules
      help[:general_commands_file] += build_help(config.path+'/rules/general_commands.rb', expanded)[user_type].values.join("\n") + "\n"
    end
    if help.key?(:on_bot)
      commands_on_extended_from_on_bot = [:repl, :see_repls, :get_repl, :run_repl, :delete_repl, :kill_repl, :ruby_code]
      commands_on_extended_from_on_bot.each do |cm|
        help[:on_extended][cm] = help[:on_bot][cm] if help[:on_bot].key?(cm)
      end      
    end
    help = remove_hash_keys(help, :admin_master) unless user_type == :master
    help = remove_hash_keys(help, :admin) unless user_type == :admin or user_type == :master
    help = remove_hash_keys(help, :on_master) unless channel_type == :master_bot
    help = remove_hash_keys(help, :on_extended) unless channel_type == :extended
    help = remove_hash_keys(help, :on_dm) unless channel_type == :direct
    txt = ""

    if (channel_type == :bot or channel_type == :master_bot) and expanded and descriptions
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
    if channel_type == :direct and expanded and descriptions
      txt += "===================================
      When on a private conversation with the Smart Bot, I'm always listening to you.\n"
    end
    unless channel_type == :master_bot or channel_type == :extended or !expanded or !descriptions
      txt += "===================================
      *Commands from Channels without a bot:*
      ----------------------------------------------
      `@BOT_NAME on #CHANNEL_NAME COMMAND`
      `@BOT_NAME #CHANNEL_NAME COMMAND`
        It will run the supplied command using the rules on the channel supplied.
        You need to join the specified channel to be able to use those rules.
        Also you can use this command to call another bot from a channel with a running bot.
      \n"
    end

    if help.key?(:general_commands_file)
      txt += "===================================
        *General commands on any channel where the Smart Bot is a member:*\n" if descriptions
      txt += help.general_commands_file
    end

    if help.key?(:on_bot) and help.on_bot.key?(:general) and channel_type != :external and channel_type != :extended
      if descriptions
        if channel_type == :direct
          txt += "===================================
          *General commands:*\n"
        else
          txt += "===================================
          *General commands on Bot channel even when the Smart Bot is not listening to you:*\n"
        end
      end
      order.on_bot_general.each do |o|
        txt += help.on_bot.general[o]
      end
      if channel_type == :master_bot
        txt += help.on_master.create_bot
        txt += help.on_master.where_smartbot
      end
    end

    if help.key?(:on_bot) and channel_type != :external and channel_type != :extended
      if descriptions
        if channel_type == :direct
          txt += "===================================
          *General commands on bot, DM or on external call on demand:*\n"
        else
          txt += "===================================
          *General commands on Bot channel only when the Smart Bot is listening to you or on demand:*\n"
        end
      end
      order.on_bot.each do |o|
        txt += help.on_bot[o]
      end
    end
    if help.key?(:on_extended) and channel_type == :extended and help[:on_extended].keys.size > 0
      if descriptions
        txt += "===================================
        *General commands on Extended channel only on demand:*\n"
      end
      commands_on_extended_from_on_bot.each do |o|
        txt += help.on_extended[o]
      end
    end

    if help.key?(:on_bot) and help.on_bot.key?(:admin) and channel_type != :external and channel_type != :extended
      txt += "===================================
        *Admin commands:*\n\n" if descriptions
      order.on_bot_admin.each do |o|
        txt += help.on_bot.admin[o]
      end
      if help.key?(:on_master) and help.on_master.key?(:admin)
        help.on_master.admin.each do |k, v|
          txt += v if v.is_a?(String)
        end
      end
    end

    if help.key?(:on_bot) and help.on_bot.key?(:admin_master) and help.on_bot.admin_master.size > 0 and channel_type != :external and channel_type != :extended
      txt += "===================================
        *Master Admin commands:*\n" if descriptions
      help.on_bot.admin_master.each do |k, v|
        txt += v if v.is_a?(String)
      end
    end

    if help.key?(:on_master) and help.on_master.key?(:admin_master) and help.on_master.admin_master.size > 0 and channel_type != :external and channel_type != :extended
      txt += "===================================
        *Master Admin commands:*\n" unless txt.include?('*Master Admin commands*') or !descriptions
      help.on_master.admin_master.each do |k, v|
        txt += v if v.is_a?(String)
      end
    end

    if help.key?(:rules_file) and channel_type != :external
      @logger.info channel_type if config.testing
      if channel_type == :extended or channel_type == :direct
        @logger.info help.rules_file if config.testing
        help.rules_file = help.rules_file.gsub(/^\s*\*These are specific commands.+NAME_OF_BOT THE_COMMAND`\s*$/im, "")
      end

      if !help.rules_file.to_s.include?('These are specific commands') and help.rules_file!=''
        txt += "===================================
         *Specific commands on this Channel, call them !THE_COMMAND or !!THE_COMMAND:*\n" if descriptions
      end
  
      txt += help.rules_file
    end
    return txt
  end
end
