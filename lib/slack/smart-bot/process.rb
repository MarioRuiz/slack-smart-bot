require_relative "commands/general/hi_bot"
require_relative "commands/general/bye_bot"
require_relative "commands/general/bot_help"
require_relative "commands/on_bot/ruby_code"
require_relative "commands/general/use_rules"
require_relative "commands/general/stop_using_rules"
require_relative "commands/on_master/admin_master/exit_bot"
require_relative "commands/on_master/admin_master/notify_message"
require_relative "commands/on_master/admin/kill_bot_on_channel"
require_relative "commands/on_master/create_bot"
require_relative "commands/on_bot/admin/add_routine"
require_relative "commands/on_bot/admin/start_bot"
require_relative "commands/on_bot/admin/pause_bot"
require_relative "commands/on_bot/admin/remove_routine"
require_relative "commands/on_bot/admin/run_routine"
require_relative "commands/on_bot/admin/pause_routine"
require_relative "commands/on_bot/admin/start_routine"
require_relative "commands/on_bot/admin/see_routines"
require_relative "commands/on_bot/admin/extend_rules"
require_relative "commands/on_bot/admin/stop_using_rules_on"
require_relative "commands/general/bot_status"
require_relative "commands/on_bot/add_shortcut"
require_relative "commands/on_bot/delete_shortcut"
require_relative "commands/on_bot/see_shortcuts"
require_relative "commands/on_extended/bot_rules"

class SlackSmartBot
  def process(user, command, dest, dchannel, rules_file, typem, files)
    from = user.name
    if user.profile.display_name.to_s.match?(/\A\s*\z/)
      user.profile.display_name = user.profile.real_name
    end
    display_name = user.profile.display_name
    processed = true

    on_demand = false
    if command.match(/^@?(#{config[:nick]}):*\s+(.+)/im) or
       command.match(/^()!(.+)/im) or
       command.match(/^()<@#{config[:nick_id]}>\s+(.+)/im)
      command = $2
      on_demand = true
    end

    #todo: check :on_pg in this case
    if typem == :on_master or typem == :on_bot or typem == :on_pg or typem == :on_dm
      case command

      when /^\s*(Hello|Hallo|Hi|Hola|What's\sup|Hey|Hæ)\s(#{@salutations.join("|")})\s*$/i
        hi_bot(user, dest, dchannel, from, display_name)
      when /^\s*(Bye|Bæ|Good\sBye|Adiós|Ciao|Bless|Bless\sBless|Adeu)\s(#{@salutations.join("|")})\s*$/i
        bye_bot(dest, from, display_name)
      when /^\s*bot\s+(rules|help)\s*(.+)?$/i, /^bot,? what can I do/i
        $1.to_s.match?(/rules/i) ? specific = true : specific = false
        help_command = $2

        bot_help(user, from, dest, dchannel, specific, help_command, rules_file)
      when /^\s*use\s+(rules\s+)?(from\s+)?<#C\w+\|(.+)>\s*$/i, /^use\s+(rules\s+)?(from\s+)?([^\s]+\s*$)/i
        channel = $3
        use_rules(dest, channel, user, dchannel)
      when /^\s*stop using rules (from\s+)<#\w+\|(.+)>/i, /^stop using rules (from\s+)(.+)/i
        channel = $2
        stop_using_rules(dest, channel, user, dchannel)
      when /^\s*extend\s+rules\s+(to\s+)<#C\w+\|(.+)>/i, /^extend\s+rules\s+(to\s+)(.+)/i,
           /^\s*use\s+rules\s+(on\s+)<#C\w+\|(.+)>/i, /^use\s+rules\s+(on\s+)(.+)/i
        channel = $2
        extend_rules(dest, user, from, channel, typem)
      when /^\s*stop using rules (on\s+)<#\w+\|(.+)>/i, /^stop using rules (on\s+)(.+)/i
        channel = $2
        stop_using_rules_on(dest, user, from, channel, typem)
      when /^\s*exit\sbot\s*$/i, /^quit\sbot\s*$/i, /^close\sbot\s*$/i
        exit_bot(command, from, dest, display_name)
      when /^\s*start\s(this\s)?bot$/i
        start_bot(dest, from)
      when /^\s*pause\s(this\s)?bot$/i
        pause_bot(dest, from)
      when /^\s*bot\sstatus/i
        bot_status(dest, from)
      when /\Anotify\s+<#(C\w+)\|.+>\s+(.+)\s*\z/im, /\Anotify\s+(all)?\s*(.+)\s*\z/im
        where = $1
        message = $2
        notify_message(dest, from, where, message)
      when /^\s*create\s+(cloud\s+)?bot\s+on\s+<#C\w+\|(.+)>\s*/i, /^create\s+(cloud\s+)?bot\s+on\s+(.+)\s*/i
        cloud = !$1.nil?
        channel = $2
        create_bot(dest, from, cloud, channel)
      when /^\s*kill\sbot\son\s<#C\w+\|(.+)>\s*$/i, /^kill\sbot\son\s(.+)\s*$/i
        channel = $1
        kill_bot_on_channel(dest, from, channel)
      when /^\s*(add|create)\s+routine\s+(\w+)\s+(every)\s+(\d+)\s*(days|hours|minutes|seconds|mins|min|secs|sec|d|h|m|s)\s*(\s.+)?\s*$/i,
           /^\s*(add|create)\s+routine\s+(\w+)\s+(at)\s+(\d+:\d+:?\d+?)\s*()(\s.+)?\s*$/i
        name = $2.downcase
        type = $3
        number_time = $4
        period = $5
        command_to_run = $6
        add_routine(dest, from, user, name, type, number_time, period, command_to_run, files)
      when /^\s*(kill|delete|remove)\s+routine\s+(\w+)\s*$/i
        name = $2.downcase
        remove_routine(dest, from, name)
      when /^\s*(run|execute)\s+routine\s+(\w+)\s*$/i
        name = $2.downcase
        run_routine(dest, from, name)
      when /^\s*pause\s+routine\s+(\w+)\s*$/i
        name = $1.downcase
        pause_routine(dest, from, name)
      when /^\s*start\s+routine\s+(\w+)\s*$/i
        name = $1.downcase
        start_routine(dest, from, name)
      when /^\s*see\s+(all\s+)?routines\s*$/i
        all = $1.to_s != ""
        see_routines(dest, from, user, all)
      else
        processed = false
      end
    else
      processed = false
    end

    # only when :on and (listening or on demand or direct message)
    if @status == :on and
       (@questions.keys.include?(from) or
        (@listening.include?(from) and typem != :on_extended) or
        typem == :on_dm or typem == :on_pg or on_demand)
      processed2 = true

      case command

      # bot rules for extended channels
      when /^bot\s+rules\s*(.+)?$/i
        help_command = $1
        bot_rules(dest, help_command, typem, rules_file, from)
      when /^\s*(add\s)?shortcut\s(for\sall)?\s*([^:]+)\s*:\s*(.+)/i, /^(add\s)sc\s(for\sall)?\s*([^:]+)\s*:\s*(.+)/i
        for_all = $2
        shortcut_name = $3.to_s.downcase
        command_to_run = $4
        add_shortcut(dest, from, typem, for_all, shortcut_name, command, command_to_run)
      when /^\s*delete\s+shortcut\s+(.+)/i, /^delete\s+sc\s+(.+)/i
        shortcut = $1.to_s.downcase
        delete_shortcut(dest, from, shortcut, typem, command)
      when /^\s*see\sshortcuts/i, /^see\ssc/i
        see_shortcuts(dest, from, typem)

        #kept to be backwards compatible
      when /^\s*id\schannel\s<#C\w+\|(.+)>\s*/i, /^id channel (.+)/
        unless typem == :on_extended
          channel_name = $1
          get_channels_name_and_id()
          if @channels_id.keys.include?(channel_name)
            respond "the id of #{channel_name} is #{@channels_id[channel_name]}", dest
          else
            respond "channel: #{channel_name} not found", dest
          end
        end
      when /^\s*ruby\s(.+)/im, /^\s*code\s(.+)/im
        code = $1
        code.gsub!("\\n", "\n")
        code.gsub!("\\r", "\r")
        @logger.info code
        ruby_code(dest, code, rules_file)
      else
        processed2 = false
      end #of case

      processed = true if processed or processed2
    end

    return processed
  end
end
