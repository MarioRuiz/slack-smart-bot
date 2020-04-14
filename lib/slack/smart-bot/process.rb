class SlackSmartBot
  def process(user, command, dest, dchannel, rules_file, typem, files, ts)
    from = user.name
    
    if user.profile.display_name.to_s.match?(/\A\s*\z/)
      user.profile.display_name = user.profile.real_name
    end
    display_name = user.profile.display_name
    processed = true

    on_demand = false
    if command.match(/^@?(#{config[:nick]}):*\s+(.+)/im) or
       command.match(/^()!!(.+)/im) or
       command.match(/^()\^(.+)/im) or
       command.match(/^()!(.+)/im) or
       command.match(/^()<@#{config[:nick_id]}>\s+(.+)/im)
        command2 = $2
        Thread.current[:command] = command2
        if command2.match?(/^()!!(.+)/im) or
          command.match?(/^()\^(.+)/im)
          Thread.current[:on_thread] = true
        end
        command = command2
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
        bot_status(dest, user)
      when /\Anotify\s+<#(C\w+)\|.+>\s+(.+)\s*\z/im, /\Anotify\s+(all)?\s*(.+)\s*\z/im
        where = $1
        message = $2
        notify_message(dest, from, where, message)
      when /^\s*create\s+(cloud\s+)?bot\s+on\s+<#C\w+\|(.+)>\s*/i, /^create\s+(cloud\s+)?bot\s+on\s+(.+)\s*/i
        cloud = !$1.nil?
        channel = $2
        create_bot(dest, user, cloud, channel)
      when /^\s*kill\sbot\son\s<#C\w+\|(.+)>\s*$/i, /^kill\sbot\son\s(.+)\s*$/i
        channel = $1
        kill_bot_on_channel(dest, from, channel)
      when /^\s*(add|create)\s+(silent\s+)?routine\s+(\w+)\s+(every)\s+(\d+)\s*(days|hours|minutes|seconds|mins|min|secs|sec|d|h|m|s)\s*(\s.+)?\s*$/i,
           /^\s*(add|create)\s+(silent\s+)?routine\s+(\w+)\s+(at)\s+(\d+:\d+:?\d+?)\s*()(\s.+)?\s*$/i
        silent = $2.to_s!=''
        name = $3.downcase
        type = $4
        number_time = $5
        period = $6
        command_to_run = $7
        add_routine(dest, from, user, name, type, number_time, period, command_to_run, files, silent)
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
      when /^\s*get\s+bot\s+logs?\s*$/i
        get_bot_logs(dest, from, typem)
      when /^\s*bot\s+stats\s*(.*)\s*$/i
        opts = $1.to_s
        all_opts = opts.downcase.split(' ')
        st_channel = opts.scan(/<#(\w+)\|.+>/).join
        st_from = opts.scan(/from\s+(\d\d\d\d[\/\-\.]\d\d[\/\-\.]\d\d)/).join
        st_from = st_from.gsub('.','-').gsub('/','-')
        st_to = opts.scan(/to\s+(\d\d\d\d[\/\-\.]\d\d[\/\-\.]\d\d)/).join
        st_to = st_to.gsub('.','-').gsub('/','-')
        st_user = opts.scan(/<@([^>]+)>/).join
        exclude_masters = opts.match?(/exclude\s+masters?/i)
        if all_opts.include?('today')
          st_from = st_to = "#{Time.now.strftime("%Y-%m-%d")}"
        end
        exclude_command = opts.scan(/exclude\s+([^\s]+)/i).join
        exclude_command = '' if exclude_command == 'masters'
        bot_stats(dest, from, typem, st_channel, st_from, st_to, st_user, exclude_masters, exclude_command)
      else
        processed = false
      end
    else
      processed = false
    end

    # only when :on and (listening or on demand or direct message)
    if @status == :on and
       (@questions.key?(from) or
       (@repl_sessions.key?(from) and dest==@repl_sessions[from][:dest] and 
        ((@repl_sessions[from][:on_thread] and Thread.current[:thread_ts] == @repl_sessions[from][:thread_ts]) or
         (!@repl_sessions[from][:on_thread] and !Thread.current[:on_thread]))) or 
         (@listening.key?(from) and typem != :on_extended and 
         ((@listening[from].key?(dest) and !Thread.current[:on_thread]) or 
          (@listening[from].key?(Thread.current[:thread_ts]) and Thread.current[:on_thread] ) )) or
        typem == :on_dm or typem == :on_pg or on_demand)
      processed2 = true

      case command

      # bot rules for extended channels
      when /^bot\s+rules\s*(.+)?$/i
        help_command = $1
        bot_rules(dest, help_command, typem, rules_file, user)
      when /^\s*(add\s)?shortcut\s(for\sall)?\s*([^:]+)\s*:\s*(.+)/i, /^(add\s)sc\s(for\sall)?\s*([^:]+)\s*:\s*(.+)/i
        for_all = $2
        shortcut_name = $3.to_s.downcase
        command_to_run = $4
        add_shortcut(dest, user, typem, for_all, shortcut_name, command, command_to_run)
      when /^\s*(delete|remove)\s+shortcut\s+(.+)/i, /^(delete|remove)\s+sc\s+(.+)/i
        shortcut = $2.to_s.downcase
        delete_shortcut(dest, user, shortcut, typem, command)
      when /^\s*see\sshortcuts/i, /^see\ssc/i
        see_shortcuts(dest, user, typem)

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
        ruby_code(dest, user, code, rules_file)
      when /^\s*(private\s+)?(repl|irb|live)\s*()()()$/i, 
        /^\s*(private\s+)?(repl|irb|live)\s+([\w\-]+)()()\s*$/i,
        /^\s*(private\s+)?(repl|irb|live)\s+([\w\-]+)\s*:\s*"(.+)"()\s*$/i,
        /^\s*(private\s+)?(repl|irb|live)\s+([\w\-]+)\s*:\s*"(.+)"\s+(.+)\s*$/i,
        /^\s*(private\s+)?(repl|irb|live)\s+([\w\-]+)()\s+(.+)\s*$/i,
        /^\s*(private\s+)?(repl|irb|live)()\s+()(.+)\s*$/i
        if $1.to_s!=''
          type = :private
        else
          type = :public
        end
        session_name = $3
        description = $4
        opts = " #{$5}"
        env_vars = opts.scan(/\s+[\w\-]+="[^"]+"/i) + opts.scan(/\s+[\w\-]+='[^']+'/i)  
        opts.scan(/\s+[\w\-]+=[^'"\s]+/i).flatten.each do |ev|
          env_vars << ev.gsub('=',"='") + "'"
        end
        env_vars.each_with_index do |ev, idx|
            ev.gsub!("=","']=")
            ev.lstrip!
            env_vars[idx] = "ENV['#{ev}"
        end
        repl(dest, user, session_name, env_vars.flatten, rules_file, command, description, type)
      when /^\s*get\s+(repl|irb|live)\s+([\w\-]+)\s*/i
        session_name = $2
        get_repl(dest, user, session_name)      
      when /^\s*run\s+(repl|irb|live)\s+([\w\-]+)()\s*$/i,
        /^\s*run\s+(repl|irb|live)\s+([\w\-]+)\s+(.+)\s*$/i
        session_name = $2
        opts = " #{$3}"
        env_vars = opts.scan(/\s+[\w\-]+="[^"]+"/i) + opts.scan(/\s+[\w\-]+='[^']+'/i)  
        opts.scan(/\s+[\w\-]+=[^'"\s]+/i).flatten.each do |ev|
          env_vars << ev.gsub('=',"='") + "'"
        end
        env_vars.each_with_index do |ev, idx|
            ev.gsub!("=","']=")
            ev.lstrip!
            env_vars[idx] = "ENV['#{ev}"
        end
        run_repl(dest, user, session_name, env_vars.flatten, rules_file)      
      when /^\s*(delete|remove)\s+(repl|irb|live)\s+([\w\-]+)\s*$/i
        repl_name = $3.downcase
        delete_repl(dest, user, repl_name)
      when /^\s*see\s+(repls|repl|irb|irbs)\s*$/i
        see_repls(dest, user, typem)
      else
        processed2 = false
      end #of case

      processed = true if processed or processed2
    end

    return processed
  end
end
