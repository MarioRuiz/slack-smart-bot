class SlackSmartBot
  def process(user, command, dest, dchannel, rules_file, typem, files, ts)
    from = user.name
    if config.simulate
      display_name = user.profile.display_name
    else
      if user.profile.display_name.to_s.match?(/\A\s*\z/)
        user.profile.display_name = user.profile.real_name
      end
      display_name = user.profile.display_name
    end
    
    processed = true

    on_demand = false
    if command.match(/\A@?(#{config[:nick]}):*\s+(.+)/im) or
       command.match(/\A()!!(.+)/im) or
       command.match(/\A()\^(.+)/im) or
       command.match(/\A()!(.+)/im) or
       command.match(/\A()<@#{config[:nick_id]}>\s+(.+)/im)
        command2 = $2
        Thread.current[:command] = command2
        if command2.match?(/^()!!(.+)/im) or
          command.match?(/^()\^(.+)/im)
          Thread.current[:on_thread] = true
        end
        command = command2
        on_demand = true
    end
    if (on_demand or typem == :on_dm or
      (@listening.key?(from) and (@listening[from].key?(dest) or @listening[from].key?(Thread.current[:thread_ts])) )) and 
      config.on_maintenance and !command.match?(/\A(set|turn)\s+maintenance\s+off\s*\z/)
      respond config.on_maintenance_message, dest unless Thread.current.key?(:routine) and Thread.current[:routine]
      processed = true
    end

    if !config.on_maintenance or (config.on_maintenance and command.match?(/\A(set|turn)\s+maintenance\s+off\s*\z/))
      #todo: check :on_pg in this case
      if typem == :on_master or typem == :on_bot or typem == :on_pg or typem == :on_dm
    
        case command

        when /\A\s*(Hello|Hallo|Hi|Hola|What's\sup|Hey|Hæ)\s+(#{@salutations.join("|")})\s*$/i
          hi_bot(user, dest, dchannel, from, display_name)
        when /\A\s*what's\s+new\s*$/i
          whats_new(user, dest, dchannel, from, display_name)
        when /\A\s*(Bye|Bæ|Good\s+Bye|Adiós|Ciao|Bless|Bless\sBless|Adeu)\s+(#{@salutations.join("|")})\s*$/i
          bye_bot(dest, from, display_name)
        when /\A\s*(#{@salutations.join("|")})\s+(rules|help)\s*(.+)?$/i, /\A(#{@salutations.join("|")}),? what can I do/i
          $2.to_s.match?(/rules/i) ? specific = true : specific = false
          help_command = $3
          bot_help(user, from, dest, dchannel, specific, help_command, rules_file)
        when /\A\s*(suggest|random)\s+(command|rule)\s*\z/i, /\A\s*(command|rule)\s+suggestion\s*\z/i
          $2.to_s.match?(/rule/i) || $1.to_s.match?(/rule/i) ? specific = true : specific = false
          suggest_command(from, dest, dchannel, specific, rules_file)
        when /\A\s*use\s+(rules\s+)?(from\s+)?<#C\w+\|(.+)>\s*$/i, /\Ause\s+(rules\s+)?(from\s+)?([^\s]+\s*$)/i
          channel = $3
          use_rules(dest, channel, user, dchannel)
        when /\A\s*stop\s+using\s+rules\s+(from\s+)<#\w+\|(.+)>/i, /\A\s*stop\s+using\s+rules\s+(from\s+)(.+)/i
          channel = $2
          stop_using_rules(dest, channel, user, dchannel)
        when /\A\s*extend\s+rules\s+(to\s+)<#C\w+\|(.+)>/i, /\A\s*extend\s+rules\s+(to\s+)(.+)/i,
            /\A\s*use\s+rules\s+(on\s+)<#C\w+\|(.+)>/i, /\A\s*use\s+rules\s+(on\s+)(.+)/i
          channel = $2
          extend_rules(dest, user, from, channel, typem)
        when /\A\s*stop\s+using\s+rules\s+(on\s+)<#\w+\|(.+)>/i, /\A\s*stop\s+using\s+rules\s+(on\s+)(.+)/i
          channel = $2
          stop_using_rules_on(dest, user, from, channel, typem)
        when /\A\s*exit\s+bot\s*$/i, /\A\s*quit\s+bot\s*$/i, /\A\s*close\s+bot\s*$/i
          exit_bot(command, from, dest, display_name)
        when /\A\s*start\s+(this\s+)?bot$/i
          start_bot(dest, from)
        when /\A\s*pause\s+(this\s+)?bot$/i
          pause_bot(dest, from)
        when /\A\s*bot\s+status/i
          bot_status(dest, user)
        when /\Anotify\s+<#(C\w+)\|.+>\s+(.+)\s*\z/im, /\Anotify\s+(all)?\s*(.+)\s*\z/im
          where = $1
          message = $2
          notify_message(dest, from, where, message)
        when /\A\s*create\s+(cloud\s+|silent\s+)?bot\s+on\s+<#C\w+\|(.+)>\s*/i, 
          /\Acreate\s+(cloud\s+|silent\s+)?bot\s+on\s+#(.+)\s*/i, 
          /\Acreate\s+(cloud\s+|silent\s+)?bot\s+on\s+(.+)\s*/i
          type = $1.to_s.downcase
          channel = $2
          create_bot(dest, user, type, channel)
        when /\A\s*kill\s+bot\s+on\s+<#C\w+\|(.+)>\s*$/i, /\Akill\s+bot\s+on\s+#(.+)\s*$/i, /\Akill\s+bot\s+on\s+(.+)\s*$/i
          channel = $1
          kill_bot_on_channel(dest, from, channel)
        when /\A\s*(add|create)\s+(silent\s+)?routine\s+(\w+)\s+(every)\s+(\d+)\s*(days|hours|minutes|seconds|mins|min|secs|sec|d|h|m|s)\s*(\s#(\w+)\s*)(\s.+)?\s*$/i,
          /\A\s*(add|create)\s+(silent\s+)?routine\s+(\w+)\s+(every)\s+(\d+)\s*(days|hours|minutes|seconds|mins|min|secs|sec|d|h|m|s)\s*(\s<#(C\w+)\|.+>\s*)?(\s.+)?\s*$/i,
          /\A\s*(add|create)\s+(silent\s+)?routine\s+(\w+)\s+on\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday|weekend|weekday)s?\s+at\s+(\d+:\d+:?\d+?)\s*()(\s#(\w+)\s*)(\s.+)?\s*$/i,
          /\A\s*(add|create)\s+(silent\s+)?routine\s+(\w+)\s+on\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday|weekend|weekday)s?\s+at\s+(\d+:\d+:?\d+?)\s*()(\s<#(C\w+)\|.+>\s*)?(\s.+)?\s*$/i,
          /\A\s*(add|create)\s+(silent\s+)?routine\s+(\w+)\s+(at)\s+(\d+:\d+:?\d+?)\s*()(\s#(\w+)\s*)(\s.+)?\s*$/i,
          /\A\s*(add|create)\s+(silent\s+)?routine\s+(\w+)\s+(at)\s+(\d+:\d+:?\d+?)\s*()(\s<#(C\w+)\|.+>\s*)?(\s.+)?\s*$/i
          silent = $2.to_s!=''
          name = $3.downcase
          type = $4.to_s.downcase
          number_time = $5
          period = $6
          channel = $8
          command_to_run = $9
          add_routine(dest, from, user, name, type, number_time, period, command_to_run, files, silent, channel)
        when /\A\s*(kill|delete|remove)\s+routine\s+(\w+)\s*$/i
          name = $2.downcase
          remove_routine(dest, from, name)
        when /\A\s*(run|execute)\s+routine\s+(\w+)\s*$/i
          name = $2.downcase
          run_routine(dest, from, name)
        when /\A\s*pause\s+routine\s+(\w+)\s*$/i
          name = $1.downcase
          pause_routine(dest, from, name)
        when /\A\s*start\s+routine\s+(\w+)\s*$/i
          name = $1.downcase
          start_routine(dest, from, name)
        when /\A\s*see\s+(all\s+)?routines\s*$/i
          all = $1.to_s != ""
          see_routines(dest, from, user, all)
        when /\A\s*get\s+bot\s+logs?\s*$/i
          get_bot_logs(dest, from, typem)
        when /\A\s*send\s+message\s+(on|to|in)\s*([^\s]+)\s+([^\s]+)\s*:\s*(.+)\s*$/i,
          /\A\s*send\s+message\s+(on|to|in)\s*([^\s]+)\s*():\s*(.+)\s*$/i
          to = $2
          thread_ts = $3.to_s
          message = $4
          to_channel = to.scan(/<#([^>]+)\|.+>/).join
          to_channel = to.scan(/#([^\s]+)/).join if to_channel == ''
          if to_channel == ''
            to_user = to.scan(/<@(\w+)>/).join
            if to_user == ''
              # message_id
            else
              to = to_user
            end
          else
            to = to_channel
          end
          send_message(dest, from, typem, to, thread_ts, message)
        when /\A\s*react\s+(on|to|in)\s*([^\s]+)\s+([^\s]+)\s+(.+)\s*$/i
          to = $2
          thread_ts = $3.to_s
          emojis = $4
          to_channel = to.scan(/<#([^>]+)\|.+>/).join
          if to_channel == ''
            to_channel = to.scan(/#([^\s]+)/).join
            to_channel = @channels_id[to_channel].to_s
          end
          if to_channel == ''
            respond "The channel specified doesn't exist or is in a incorrect format"
          else
            to = to_channel
            react_to(dest, from, typem, to, thread_ts, emojis)
          end

        when /\A\s*(leader\s+board|leaderboard|ranking|podium)()()\s*$/i,
          /\A\s*(leader\s+board|leaderboard|ranking|podium)\s+(from\s+(\d\d\d\d[\/\-\.]\d\d[\/\-\.]\d\d))()\s*$/i,
          /\A\s*(leader\s+board|leaderboard|ranking|podium)\s+(from\s+(\d\d\d\d[\/\-\.]\d\d[\/\-\.]\d\d))\s+(to\s+(\d\d\d\d[\/\-\.]\d\d[\/\-\.]\d\d))\s*$/i,
          /\A\s*(leader\s+board|leaderboard|ranking|podium)\s+(today|yesterday|last\s+week|this\s+week|last\s+month|this\s+month|last\s+year|this year)()\s*$/i
          require 'date'
          opt1 = $2.to_s
          to = $3.to_s
          if opt1.match?(/\d/)
            from = opt1
            period = ''
            from = from.gsub('.','-').gsub('/','-')
            to = to.gsub('.','-').gsub('/','-') unless to.empty?
          elsif opt1.to_s==''
            period = 'last week'
            date = Date.today
            wday = date.wday
            wday = 7 if wday==0
            wday-=1
            from = "#{(date-wday-7).strftime("%Y-%m-%d")}"
            to = "#{(date-wday-1).strftime("%Y-%m-%d")}"
          else
            from = ''
            period = opt1.downcase
            case period
            when 'today'
              from = to = "#{Date.today.strftime("%Y-%m-%d")}"
            when 'yesterday'
              from = to ="#{(Date.today-1).strftime("%Y-%m-%d")}"
            when /this\s+month/
              from = "#{Date.today.strftime("%Y-%m-01")}"
              to = "#{Date.today.strftime("%Y-%m-%d")}"
            when /last\s+month/
              date = Date.today<<1
              from = "#{date.strftime("%Y-%m-01")}"
              to = "#{(Date.new(date.year, date.month, -1)).strftime("%Y-%m-%d")}"
            when /this\s+year/
              from = "#{Date.today.strftime("%Y-01-01")}"
              to = "#{Date.today.strftime("%Y-%m-%d")}"
            when /last\s+year/
              date = Date.today.prev_year
              from = "#{date.strftime("%Y-01-01")}"
              to = "#{(Date.new(date.year, 12, 31)).strftime("%Y-%m-%d")}"
            when /this\s+week/
              date = Date.today
              wday = date.wday
              wday = 7 if wday==0
              wday-=1
              from = "#{(date-wday).strftime("%Y-%m-%d")}"
              to = "#{date.strftime("%Y-%m-%d")}"
            when /last\s+week/
              date = Date.today
              wday = date.wday
              wday = 7 if wday==0
              wday-=1
              from = "#{(date-wday-7).strftime("%Y-%m-%d")}"
              to = "#{(date-wday-1).strftime("%Y-%m-%d")}"
            end
          end

          leaderboard(from, to, period)

        when /\A\s*bot\s+stats\s*(.*)\s*$/i
          opts = $1.to_s
          all_opts = opts.downcase.split(' ')
          all_data = all_opts.include?('alldata')
          st_channel = opts.scan(/<#(\w+)\|.+>/).join
          st_from = opts.scan(/from\s+(\d\d\d\d[\/\-\.]\d\d[\/\-\.]\d\d)/).join
          st_from = st_from.gsub('.','-').gsub('/','-')
          st_to = opts.scan(/to\s+(\d\d\d\d[\/\-\.]\d\d[\/\-\.]\d\d)/).join
          st_to = st_to.gsub('.','-').gsub('/','-')
          st_user = opts.scan(/<@([^>]+)>/).join
          st_command = opts.scan(/\s+command\s+(\w+)/i).join.downcase
          st_command = opts.scan(/^command\s+(\w+)/i).join.downcase if st_command == ''
          exclude_masters = all_opts.include?('exclude') && all_opts.include?('masters')
          exclude_routines = all_opts.include?('exclude') && all_opts.include?('routines')
          if exclude_masters
            opts.gsub!(/\s+masters$/,'')
            opts.gsub!(/\s+masters\s+/,'')
          end
          if exclude_routines
            opts.gsub!(/\s+routines$/,'')
            opts.gsub!(/\s+routines\s+/,'')
          end
          monthly = false
          if all_opts.include?('today')
            st_from = st_to = "#{Time.now.strftime("%Y-%m-%d")}"
          elsif all_opts.include?('monthly')
            monthly = true
          end
          exclude_command = opts.scan(/exclude\s+([^\s]+)/i).join
          unless @master_admin_users_id.include?(user.id)
            st_user = user.id
          end
          if (typem == :on_master or typem == :on_bot) and dest[0]!='D' #routine bot stats to be published on DM
            st_channel = dchannel
          end
          bot_stats(dest, user, typem, st_channel, st_from, st_to, st_user, st_command, exclude_masters, exclude_routines, exclude_command, monthly, all_data)
        when /\A(set|turn)\s+maintenance\s+(on|off)\s*()\z/im, /\A(set|turn)\s+maintenance\s+(on)\s*(.+)\s*\z/im
          status = $2.downcase
          message = $3.to_s
          set_maintenance(from, status, message)
        else
          processed = false
        end
      else
        processed = false
      end

      # only when :on and (listening or on demand or direct message)
      if @status == :on and
        (!answer.empty? or
        (@repl_sessions.key?(from) and dest==@repl_sessions[from][:dest] and 
          ((@repl_sessions[from][:on_thread] and Thread.current[:thread_ts] == @repl_sessions[from][:thread_ts]) or
          (!@repl_sessions[from][:on_thread] and !Thread.current[:on_thread]))) or 
          (@listening.key?(from) and typem != :on_extended and 
          ((@listening[from].key?(dest) and !Thread.current[:on_thread]) or 
            (@listening[from].key?(Thread.current[:thread_ts]) and Thread.current[:on_thread] ) )) or
          typem == :on_dm or typem == :on_pg or on_demand)
        processed2 = true
    
        case command

        when /\A\s*(add\s+)?(global\s+|generic\s+)?shortcut\s+(for\sall)?\s*([^:]+)\s*:\s*(.+)/i, 
          /\A(add\s+)(global\s+|generic\s+)?sc\s+(for\sall)?\s*([^:]+)\s*:\s*(.+)/i
          for_all = $3
          shortcut_name = $4.to_s.downcase
          command_to_run = $5
          global = $2.to_s != ''
          add_shortcut(dest, user, typem, for_all, shortcut_name, command, command_to_run, global)
        when /\A\s*(delete|remove)\s+(global\s+|generic\s+)?shortcut\s+(.+)/i, 
          /\A(delete|remove)\s+(global\s+|generic\s+)?sc\s+(.+)/i
          shortcut = $3.to_s.downcase
          global = $2.to_s != ''

          delete_shortcut(dest, user, shortcut, typem, command, global)
        when /\A\s*see\s+shortcuts/i, /^see\ssc/i
          see_shortcuts(dest, user, typem)

          #kept to be backwards compatible
        when /\A\s*id\schannel\s<#C\w+\|(.+)>\s*/i, /^id channel (.+)/
          unless typem == :on_extended
            channel_name = $1
            get_channels_name_and_id()
            if @channels_id.keys.include?(channel_name)
              respond "the id of #{channel_name} is #{@channels_id[channel_name]}", dest
            else
              respond "channel: #{channel_name} not found", dest
            end
          end
        when /\A\s*ruby\s(.+)/im, /\A\s*code\s(.+)/im
          code = $1
          code.gsub!("\\n", "\n")
          code.gsub!("\\r", "\r")
          @logger.info code
          ruby_code(dest, user, code, rules_file)
        when /\A\s*(private\s+|clean\s+|clean\s+private\s+|private\s+clean\s+)?(repl|irb|live)\s*()()()\z/i, 
          /\A\s*(private\s+|clean\s+|clean\s+private\s+|private\s+clean\s+)?(repl|irb|live)\s+([\w\-]+)()()\s*\z/i,
          /\A\s*(private\s+|clean\s+|clean\s+private\s+|private\s+clean\s+)?(repl|irb|live)\s+([\w\-]+)\s*:\s+"([^"]+)"()\s*\z/i,
          /\A\s*(private\s+|clean\s+|clean\s+private\s+|private\s+clean\s+)?(repl|irb|live)\s+([\w\-]+)\s*:\s+"([^"]+)"\s+(.+)\s*\z/i,
          /\A\s*(private\s+|clean\s+|clean\s+private\s+|private\s+clean\s+)?(repl|irb|live)\s+([\w\-]+)()\s+(.+)\s*\z/i,
          /\A\s*(private\s+|clean\s+|clean\s+private\s+|private\s+clean\s+)?(repl|irb|live)()\s+()(.+)\s*\z/i
          opts_type = $1.to_s.downcase.split(' ')
          opts_type.include?('private') ? type = :private : type = :public
          type = "#{type}_clean".to_sym if opts_type.include?('clean')
          
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
        when /\A\s*get\s+(repl|irb|live)\s+([\w\-]+)\s*/i
          session_name = $2
          get_repl(dest, user, session_name)      
        when /\A\s*run\s+(repl|irb|live)\s+([\w\-]+)()\s*$/i,
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
        when /\A\s*(delete|remove)\s+(repl|irb|live)\s+([\w\-]+)\s*$/i
          repl_name = $3
          delete_repl(dest, user, repl_name)
        when /\A\s*see\s+(repls|repl|irb|irbs)\s*$/i
          see_repls(dest, user, typem)
        else
          processed2 = false
        end #of case

        processed = true if processed or processed2
      end
    end
    return processed
  end
end
