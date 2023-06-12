class SlackSmartBot
  def process_first(user, text, dest, dchannel, typem, files, ts, thread_ts, routine, routine_name, routine_type, command_orig)
    nick = user.name
    rules_file = ""
    if text.match(/\A\s*(stop|quit|exit|kill)\s+(iterator|iteration|loop)\s+(\d+)\s*\z/i)
      save_stats :quit_loop, forced: true, data: {dest: dest, typem: typem, user: user, files: false, command: text, routine: routine}
      num_iteration = $3.to_i
      if config.admins.include?(user.name) or @loops.key?(user.name)
        if config.admins.include?(user.name)
          name_loop = ''
          @loops.each do |k,v|
            if v.include?(num_iteration)
              name_loop = k
              break
            end
          end
        else
          name_loop = user.name
        end
        if @loops.key?(name_loop) and @loops[name_loop].include?(num_iteration)
          @loops[name_loop].delete(num_iteration)
          respond "Loop #{num_iteration} stopped", dest, thread_ts: thread_ts
        else
          respond "You don't have any loop with id #{num_iteration}. Only the creator of the loop or an admin can stop the loop.", dest, thread_ts: thread_ts
        end
      else
        respond "Only the creator of the loop or an admin can stop the loop.", dest, thread_ts: thread_ts
      end
      if Thread.current.key?(:encrypted) and Thread.current[:encrypted].size > 0
        found = false
        Thread.current[:encrypted].each do |encdata|
          found = true if !found and text.include?(encdata)
          text.gsub!(encdata, "********")
        end
        text = "********" if !found
        text+= " (encrypted #{Thread.current[:command_id]})"
      end
      @logger.info "command: #{nick}> #{text}"
      return :next #jal
    end
    if text.match(/\A\s*!*^?\s*(for\s*)?(\d+)\s+times\s+every\s+(\d+)\s*(m|minute|minutes|s|sc|second|seconds)\s+(.+)\s*\z/i)
      save_stats :create_loop, forced: true, data: {dest: dest, typem: typem, user: user, files: false, command: text, routine: routine}
      # min every 10s, max every 60m, max times 24
      command_every = text.dup
      text = $5
      num_times = $2.to_i
      type_every = $4.downcase
      every_seconds = $3.to_i
      command_every.gsub!(/^\s*!*^?\s*/, '')
      every_seconds = (every_seconds * 60) if type_every[0] == "m"
      if num_times > 24 or every_seconds < 10 or every_seconds > 3600
        respond "You can't do that. Maximum times is 24, minimum every is 10 seconds, maximum every is 60 minutes.", dest, thread_ts: thread_ts
        return :next #jal
      end
      @loops[user.name] ||= []
      @num_loops ||= 0
      @num_loops += 1
      loop_id = @num_loops
      @loops[user.name] << loop_id
      respond "Loop #{loop_id} started. To stop the loop use: `#{['stop','quit','exit', 'kill'].sample} #{['iteration','iterator','loop'].sample} #{loop_id}`", dest, thread_ts: thread_ts
      #todo: command_orig should be reasigned maybe to remove for N times every X seconds. Check.
    else
      command_every = ''
      num_times = 1
      every_seconds = 0
    end

    text.gsub!(/^!!/, "^") # to treat it just as ^
    shared = []
    if @shares.key?(@channels_name[dest]) and (ts.to_s != "" or config.simulate) and (user.id != config.nick_id or (user.id == config.nick_id and !text.match?(/\A\*?Shares from channel/)))
      @shares[@channels_name[dest]].each do |row|
        if row[:user_deleted] == ""
          if ((row[:type] == "text" and text.include?(row[:condition][1..-2])) or (row[:type] == "regexp" and text.match?(/#{row[:condition][1..-2]}/im))) and !shared.include?(row[:to_channel])
            if config.simulate
              link = text
            else
              link = client.web_client.chat_getPermalink(channel: dest, message_ts: ts).permalink
            end
            respond "*<#{link}|Shared> by <@#{row[:user_created]}> from <##{dest}>* using share id #{row[:share_id]}", row[:to_channel]
            shared << row[:to_channel]
            sleep 0.2
          end
        end
      end
    end

    if typem == :on_call
      rules_file = config.rules_file
    elsif dest[0] == "C" or dest[0] == "G" # on a channel or private channel
      rules_file = config.rules_file

      if @rules_imported.key?(user.name) and @rules_imported[user.name].key?(dchannel)
        unless @bots_created.key?(@rules_imported[user.name][dchannel])
          get_bots_created()
        end
        if @bots_created.key?(@rules_imported[user.name][dchannel])
          rules_file = @bots_created[@rules_imported[user.name][dchannel]][:rules_file]
        end
      end
    elsif dest[0] == "D" and @rules_imported.key?(user.name) and @rules_imported[user.name].key?(user.name) #direct message
      unless @bots_created.key?(@rules_imported[user.name][user.name])
        get_bots_created()
      end
      if @bots_created.key?(@rules_imported[user.name][user.name])
        rules_file = @bots_created[@rules_imported[user.name][user.name]][:rules_file]
      end
    elsif dest[0] == "D" and (!@rules_imported.key?(user.name) or (@rules_imported.key?(user.name) and !@rules_imported[user.name].key?(user.name)))
      if File.exist?("#{config.path}/rules/general_rules.rb")
        rules_file = "/rules/general_rules.rb"
      end
    end
    if nick == config[:nick] #if message is coming from the bot
      begin
        case text
        when /^Bot has been (closed|killed) by/i
          if config.channel == @channels_name[dchannel]
            @logger.info "#{nick}: #{text}"
            if config.simulate
              @status = :off
              config.simulate = false
              Thread.exit
            else
              exit!
            end
          end
        when /^Changed status on (.+) to :(.+)/i
          channel_name = $1
          status = $2
          if config.on_master_bot or config.channel == channel_name
            @bots_created[@channels_id[channel_name]][:status] = status.to_sym
            update_bots_file()
            if config.channel == channel_name
              @logger.info "#{nick}: #{text}"
            else #on master bot
              @logger.info "Changed status on #{channel_name} to :#{status}"
            end
          end
        when /extended the rules from (.+) to be used on (.+)\.$/i
          from_name = $1
          to_name = $2
          if config.on_master_bot and @bots_created[@channels_id[from_name]][:cloud]
            @bots_created[@channels_id[from_name]][:extended] << to_name
            @bots_created[@channels_id[from_name]][:extended].uniq!
            update_bots_file()
          end
        when /removed the access to the rules of (.+) from (.+)\.$/i
          from_name = $1
          to_name = $2
          if config.on_master_bot and @bots_created[@channels_id[from_name]][:cloud]
            @bots_created[@channels_id[from_name]][:extended].delete(to_name)
            update_bots_file()
          end
        end

        return :next #don't continue analyzing #jal
      rescue Exception => stack
        @logger.fatal stack
        return :next #jal
      end
    end

    #only for shortcuts
    if text.match(/^@?(#{config[:nick]}):*\s+(.+)\s*/im) or
       text.match(/^()\^\s*(.+)\s*/im) or
       text.match(/^()!\s*(.+)\s*/im) or
       text.match(/^()<@#{config[:nick_id]}>\s+(.+)\s*/im)
      command2 = $2
      if text.match?(/^()\^\s*(.+)/im)
        add_double_excl = true
        addexcl = false
        if command2.match?(/^![^!]/) or command2.match?(/^\^/)
          command2[0] = ""
        elsif command2.match?(/^!!/)
          command2[0] = ""
          command2[1] = ""
        end
      else
        add_double_excl = false
        addexcl = true
      end
      command = command2
    else
      addexcl = false
      if text.include?("$") #for shortcuts inside commands
        command = text.lstrip.rstrip
      else
        command = text.downcase.lstrip.rstrip
      end
    end

    if command.include?("$") #for adding shortcuts inside commands
      command.scan(/\$([^\$]+)/i).flatten.each do |sc|
        sc.strip!
        if @shortcuts.key?(nick) and @shortcuts[nick].keys.include?(sc)
          command.gsub!("$#{sc}", @shortcuts[nick][sc])
        elsif @shortcuts.key?(:all) and @shortcuts[:all].keys.include?(sc)
          command.gsub!("$#{sc}", @shortcuts[:all][sc])
        elsif @shortcuts_global.key?(nick) and @shortcuts_global[nick].keys.include?(sc)
          command.gsub!("$#{sc}", @shortcuts_global[nick][sc])
        elsif @shortcuts_global.key?(:all) and @shortcuts_global[:all].keys.include?(sc)
          command.gsub!("$#{sc}", @shortcuts_global[:all][sc])
        end
      end
      command.scan(/\$([^\s]+)/i).flatten.each do |sc|
        sc.strip!
        if @shortcuts.key?(nick) and @shortcuts[nick].keys.include?(sc)
          command.gsub!("$#{sc}", @shortcuts[nick][sc])
        elsif @shortcuts.key?(:all) and @shortcuts[:all].keys.include?(sc)
          command.gsub!("$#{sc}", @shortcuts[:all][sc])
        elsif @shortcuts_global.key?(nick) and @shortcuts_global[nick].keys.include?(sc)
          command.gsub!("$#{sc}", @shortcuts_global[nick][sc])
        elsif @shortcuts_global.key?(:all) and @shortcuts_global[:all].keys.include?(sc)
          command.gsub!("$#{sc}", @shortcuts_global[:all][sc])
        end
      end
      text = command
      text = "!" + text if addexcl and text[0] != "!"
      text = "^" + text if add_double_excl
    end
    if command.scan(/^(shortcut|sc)\s+([^:]+)\s*$/i).any? or
       (@shortcuts.keys.include?(:all) and @shortcuts[:all].keys.include?(command)) or
       (@shortcuts.keys.include?(nick) and @shortcuts[nick].keys.include?(command)) or
       (@shortcuts_global.keys.include?(:all) and @shortcuts_global[:all].keys.include?(command)) or
       (@shortcuts_global.keys.include?(nick) and @shortcuts_global[nick].keys.include?(command))
      command = $2.downcase unless $2.nil?
      if @shortcuts.keys.include?(nick) and @shortcuts[nick].keys.include?(command)
        text = @shortcuts[nick][command].dup
      elsif @shortcuts.keys.include?(:all) and @shortcuts[:all].keys.include?(command)
        text = @shortcuts[:all][command].dup
      elsif @shortcuts_global.keys.include?(nick) and @shortcuts_global[nick].keys.include?(command)
        text = @shortcuts_global[nick][command].dup
      elsif @shortcuts_global.keys.include?(:all) and @shortcuts_global[:all].keys.include?(command)
        text = @shortcuts_global[:all][command].dup
      else
        respond "Shortcut not found", dest unless dest[0] == "C" and dchannel != dest #on extended channel
        return :next #jal
      end
      text = "!" + text if addexcl and text[0] != "!"
      text = "^" + text if add_double_excl
    end

    command = text

    num_times.times do |i|
      command_thread = command.dup
      begin
        t = Thread.new do
          begin
            sleep every_seconds * i if every_seconds > 0
            Thread.exit if command_every!='' and @loops.key?(user.name) and !@loops[user.name].include?(loop_id)
            @logger.info "i: #{i}, num_times: #{num_times}, every_seconds: #{every_seconds}, command: #{command_thread}" if command_every!=''
            processed = false
            processed_rules = false

            if command_thread.match?(/\A.+\s+\?\?\s+.+\z/im) and !command_thread.match?(/\A\s*(add|create)\s+(silent\s+)?(bgroutine|routine)\s+([\w\.]+)/im)
              pos = command_thread.index("??")
              Thread.current[:prompt] = command_thread[pos+2..-1].strip
              command_thread = command_thread[0..pos-1].strip
              Thread.current[:stdout] = ""
            else
              Thread.current[:prompt] = ""
              Thread.current[:stdout] = ""
            end
            Thread.current[:dest] = dest
            Thread.current[:user] = user
            Thread.current[:command] = command_thread.dup
            Thread.current[:rules_file] = rules_file
            Thread.current[:typem] = typem
            Thread.current[:files?] = !files.nil? && files.size > 0
            Thread.current[:ts] = ts
            Thread.current[:thread_ts] = thread_ts
            Thread.current[:routine] = routine
            Thread.current[:routine_name] = routine_name
            Thread.current[:routine_type] = routine_type
            Thread.current[:dchannel] = dchannel
            Thread.current[:command_orig] = command_orig.dup
            if thread_ts.to_s == ""
              Thread.current[:on_thread] = false
              Thread.current[:thread_ts] = Thread.current[:ts] # to create the thread if necessary
            else
              Thread.current[:on_thread] = true
            end
            if (dest[0] == "C") || (dest[0] == "G") and @rules_imported.key?(user.name) &&
                                                        @rules_imported[user.name].key?(dchannel) && @bots_created.key?(@rules_imported[user.name][dchannel])
              Thread.current[:using_channel] = @rules_imported[user.name][dchannel]
            elsif dest[0] == "D" && @rules_imported.key?(user.name) && @rules_imported[user.name].key?(user.name) and
                  @bots_created.key?(@rules_imported[user.name][user.name])
              Thread.current[:using_channel] = @rules_imported[user.name][user.name]
            else
              Thread.current[:using_channel] = ""
            end
            if (typem == :on_pub or typem == :on_pg) and (!command_thread.match?(/\s*bot\s+stats\s*(.*)\s*$/i) or dest != @channels_id[config.stats_channel])
              processed = false
            else
              processed = process(user, command_thread, dest, dchannel, rules_file, typem, files, Thread.current[:thread_ts])
            end
            on_demand = false
            if command_thread.match(/\A@?(#{config[:nick]}):*\s+(.+)/im) or
               command_thread.match(/\A()!!(.+)/im) or
               command_thread.match(/\A()\^(.+)/im) or
               command_thread.match(/\A()!(.+)/im) or
               command_thread.match(/\A()<@#{config[:nick_id]}>\s+(.+)/im)
              command2 = $2
              Thread.current[:command] = command2
              if command2.match?(/^()!!(.+)/im) or
                 command_thread.match?(/^()\^(.+)/im)
                Thread.current[:on_thread] = true
              end
              command_thread = command2
              on_demand = true
            end
            
            if !config.on_maintenance and @listening.key?(nick) and @listening[nick].key?(Thread.current[:thread_ts]) and !Thread.current[:thread_ts].empty? and
              ((@active_chat_gpt_sessions.key?(nick) and @active_chat_gpt_sessions[nick].key?(Thread.current[:thread_ts])) or 
              (@chat_gpt_collaborating.key?(nick) and @chat_gpt_collaborating[nick].key?(Thread.current[:thread_ts])))
              @listening[nick][Thread.current[:thread_ts]] = Time.now
              command_thread = "? #{command_thread}" #chatgpt
            end
        

            unless config.on_maintenance or @status != :on
              if typem == :on_pub or typem == :on_pg or typem == :on_extended
                if command_thread.match(/\A\s*(#{@salutations.join("|")})\s+(rules|help)\s*(.+)?$/i) or command_thread.match(/\A(#{@salutations.join("|")}),? what can I do/i)
                  $2.to_s.match?(/rules/i) ? specific = true : specific = false
                  help_command = $3
                  if typem == :on_extended and specific
                    bot_rules(dest, help_command, typem, rules_file, user)
                  else
                    bot_help(user, user.name, dest, dchannel, specific, help_command, rules_file)
                  end
                  processed = true
                end
              end
              processed = (processed || general_bot_commands(user, command_thread, dest, files))
              processed = (processed || general_commands(user, command_thread, dest, files)) if defined?(general_commands)
              if processed
                text_to_log = command_thread.dup
                
                if Thread.current.key?(:encrypted) and Thread.current[:encrypted].size > 0
                  found = false
                  Thread.current[:encrypted].each do |encdata|
                    found = true if !found and text_to_log.include?(encdata)
                    text_to_log.gsub!(encdata, "********")
                  end
                  text_to_log = "********" if !found
                  text_to_log+= " (encrypted #{Thread.current[:command_id]})"
                end
                @logger.info "command: #{nick}> #{text_to_log}"
              end
            end

            if !config.on_maintenance and !processed and typem != :on_pub and typem != :on_pg
              if @status == :on and
                 (!answer.empty? or
                  (@repl_sessions.key?(nick) and dest == @repl_sessions[nick][:dest] and
                   ((@repl_sessions[nick][:on_thread] and thread_ts == @repl_sessions[nick][:thread_ts]) or
                    (!@repl_sessions[nick][:on_thread] and !Thread.current[:on_thread]))) or
                  (@listening.key?(nick) and typem != :on_extended and
                   ((@listening[nick].key?(dest) and !Thread.current[:on_thread]) or
                    (@listening[nick].key?(thread_ts) and Thread.current[:on_thread]))) or
                  dest[0] == "D" or on_demand)
                  unless processed
                    text_to_log = command_thread.dup
                    found = false
                    if Thread.current.key?(:encrypted) and Thread.current[:encrypted].size > 0
                      Thread.current[:encrypted].each do |encdata|
                        found = true if !found and text_to_log.include?(encdata)
                        text_to_log.gsub!(encdata, "********")
                      end
                      text_to_log = "********" if !found
                      text_to_log+= " (encrypted #{Thread.current[:command_id]})"
                    end
                    @logger.info "command: #{nick}> #{text_to_log}"
                  end
                #todo: verify this

                if dest[0] == "C" or dest[0] == "G" or (dest[0] == "D" and typem == :on_call)
                  if typem != :on_call and @rules_imported.key?(user.name) and @rules_imported[user.name].key?(dchannel)
                    if @bots_created.key?(@rules_imported[user.name][dchannel])
                      if @bots_created[@rules_imported[user.name][dchannel]][:status] != :on
                        respond "The bot on that channel is not :on", dest
                        rules_file = ""
                      end
                    end
                  end
                  unless rules_file.empty?
                    begin
                      eval(File.new(config.path + rules_file).read) if File.exist?(config.path + rules_file)
                    rescue Exception => stack
                      @logger.fatal "ERROR ON RULES FILE: #{rules_file}"
                      @logger.fatal stack
                    end
                    if defined?(rules)
                      command_thread[0] = "" if command_thread[0] == "!"
                      command_thread.gsub!(/^@\w+:*\s*/, "")
                      if method(:rules).parameters.size == 4
                        processed_rules = rules(user, command_thread, processed, dest)
                      elsif method(:rules).parameters.size == 5
                        processed_rules = rules(user, command_thread, processed, dest, files)
                      else
                        processed_rules = rules(user, command_thread, processed, dest, files, rules_file)
                      end
                    else
                      @logger.warn "It seems like rules method is not defined"
                    end
                  end
                elsif @rules_imported.key?(user.name) and @rules_imported[user.name].key?(user.name)
                  if @bots_created.key?(@rules_imported[user.name][user.name])
                    if @bots_created[@rules_imported[user.name][user.name]][:status] == :on
                      begin
                        eval(File.new(config.path + rules_file).read) if File.exist?(config.path + rules_file) and ![".", ".."].include?(config.path + rules_file)
                      rescue Exception => stack
                        @logger.fatal "ERROR ON imported RULES FILE: #{rules_file}"
                        @logger.fatal stack
                      end
                    else
                      respond "The bot on <##{@rules_imported[user.name][user.name]}|#{@bots_created[@rules_imported[user.name][user.name]][:channel_name]}> is not :on", dest
                      rules_file = ""
                    end
                  end

                  unless rules_file.empty?
                    if defined?(rules)
                      command_thread[0] = "" if command_thread[0] == "!"
                      command_thread.gsub!(/^@\w+:*\s*/, "")
                      if method(:rules).parameters.size == 4
                        processed_rules = rules(user, command_thread, processed, dest)
                      elsif method(:rules).parameters.size == 5
                        processed_rules = rules(user, command_thread, processed, dest, files)
                      else
                        processed_rules = rules(user, command_thread, processed, dest, files, rules_file)
                      end
                    else
                      @logger.warn "It seems like rules method is not defined"
                    end
                  end
                elsif dest[0] == "D" and
                      (!@rules_imported.key?(user.name) or (@rules_imported.key?(user.name) and !@rules_imported[user.name].key?(user.name))) and
                      rules_file.include?("general_rules.rb")
                  begin
                    eval(File.new(config.path + rules_file).read) if File.exist?(config.path + rules_file) and ![".", ".."].include?(config.path + rules_file)
                  rescue Exception => stack
                    @logger.fatal "ERROR ON imported RULES FILE: #{rules_file}"
                    @logger.fatal stack
                  end

                  if defined?(general_rules)
                    command_thread[0] = "" if command_thread[0] == "!"
                    command_thread.gsub!(/^@\w+:*\s*/, "")
                    #todo: check to change processed > processed_rules
                    if method(:general_rules).parameters.size == 4
                      processed = general_rules(user, command_thread, processed, dest)
                    elsif method(:general_rules).parameters.size == 5
                      processed = general_rules(user, command_thread, processed, dest, files)
                    else
                      processed = general_rules(user, command_thread, processed, dest, files, rules_file)
                    end
                  else
                    @logger.warn "It seems like general_rules method is not defined"
                  end
                  unless processed
                    dont_understand("")
                  end
                else
                  @logger.info "it is a direct message with no rules file selected so no rules file executed."
                  if command_thread.match?(/^\s*bot\s+rules\s*(.*)$/i)
                    respond "No rules running. You can use the command `use rules from CHANNEL` to specify the rules you want to use on this private conversation.\n`bot help` to see available commands.", dest
                  end
                  unless processed
                    dont_understand("")
                  end
                end

                processed = (processed_rules || processed)

                if processed and @listening.key?(nick)
                  if Thread.current[:on_thread] and @listening[nick].key?(Thread.current[:thread_ts])
                    @listening[nick][Thread.current[:thread_ts]] = Time.now
                  elsif !Thread.current[:on_thread] and @listening[nick].key?(dest)
                    @listening[nick][dest] = Time.now
                  end
                end
              end
            end

            if Thread.current[:prompt].to_s != ''
              prompt = "#{Thread.current[:command]}\n\n#{Thread.current[:prompt]}\n\n#{Thread.current[:stdout]}\n\n"
              Thread.current[:prompt] = ''
              Thread.current[:stdout] = ''
              if processed
                if @active_chat_gpt_sessions.key?(user.name) and @active_chat_gpt_sessions[user.name].key?(Thread.current[:thread_ts])
                  open_ai_chat(prompt, false, :temporary)
                else
                  open_ai_chat(prompt, true, :temporary, model: config[:ai].open_ai.chat_gpt.smartbot_model)
                end
              end
            end              
            if processed and config.general_message != "" and !routine
              respond eval("\"" + config.general_message + "\"")
            end
            respond "_*Loop #{loop_id}* (#{i+1}/#{num_times}) <@#{user.name}>: #{command_every}_" if command_every!='' and processed
            @loops[user.name].delete(loop_id) if command_every!='' and !processed and @loops.key?(user.name) and @loops[user.name].include?(loop_id)

          rescue Exception => stack
            @logger.fatal stack
          end
        end
      rescue => e
        @logger.error "exception: #{e.inspect}"
      end
    end
  end
end
