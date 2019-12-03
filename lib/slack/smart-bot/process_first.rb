class SlackSmartBot
  def process_first(user, text, dest, dchannel, typem, files)
    nick = user.name
    rules_file = ""
    if typem == :on_call
      rules_file = config.rules_file
    elsif dest[0] == "C" or dest[0] == "G" # on a channel or private channel
      rules_file = config.rules_file

      if @rules_imported.key?(user.id) and @rules_imported[user.id].key?(dchannel)
        unless @bots_created.key?(@rules_imported[user.id][dchannel])
          get_bots_created()
        end
        if @bots_created.key?(@rules_imported[user.id][dchannel])
          rules_file = @bots_created[@rules_imported[user.id][dchannel]][:rules_file]
        end
      end
    elsif dest[0] == "D" and @rules_imported.key?(user.id) and @rules_imported[user.id].key?(user.id) #direct message
      unless @bots_created.key?(@rules_imported[user.id][user.id])
        get_bots_created()
      end
      if @bots_created.key?(@rules_imported[user.id][user.id])
        rules_file = @bots_created[@rules_imported[user.id][user.id]][:rules_file]
      end
    end

    if nick == config[:nick] #if message is coming from the bot
      begin
        case text
        when /^Bot has been (closed|killed) by/i
          if config.channel == @channels_name[dchannel]
            @logger.info "#{nick}: #{text}"
            if config.simulate #jal
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
       text.match(/^()!\s*(.+)\s*/im) or
       text.match(/^()<@#{config[:nick_id]}>\s+(.+)\s*/im)
      command = $2
      addexcl = true
    else
      addexcl = false
      command = text.downcase.lstrip.rstrip
    end

    if command.include?('$') #for adding shortcuts inside commands
      command.scan(/\$([^\$]+)/i).flatten.each do |sc|
        sc.strip!
        if @shortcuts.key?(nick) and @shortcuts[nick].keys.include?(sc)
          command.gsub!("$#{sc}", @shortcuts[nick][sc])
        elsif @shortcuts.key?(:all) and @shortcuts[:all].keys.include?(sc)
          command.gsub!("$#{sc}", @shortcuts[:all][sc])
        end
      end
      command.scan(/\$([^\s]+)/i).flatten.each do |sc|
        sc.strip!
        if @shortcuts.key?(nick) and @shortcuts[nick].keys.include?(sc)
          command.gsub!("$#{sc}", @shortcuts[nick][sc])
        elsif @shortcuts.key?(:all) and @shortcuts[:all].keys.include?(sc)
          command.gsub!("$#{sc}", @shortcuts[:all][sc])
        end
      end
      text = command
      text = "!" + text if addexcl and text[0] != "!"
    end
    if command.scan(/^(shortcut|sc)\s+([^:]+)\s*$/i).any? or
       (@shortcuts.keys.include?(:all) and @shortcuts[:all].keys.include?(command)) or
       (@shortcuts.keys.include?(nick) and @shortcuts[nick].keys.include?(command))
      command = $2.downcase unless $2.nil?
      if @shortcuts.keys.include?(nick) and @shortcuts[nick].keys.include?(command)
        text = @shortcuts[nick][command].dup
      elsif @shortcuts.keys.include?(:all) and @shortcuts[:all].keys.include?(command)
        text = @shortcuts[:all][command].dup
      else
        respond "Shortcut not found", dest unless dest[0] == "C" and dchannel != dest #on extended channel
        return :next #jal
      end
      text = "!" + text if addexcl and text[0] != "!"
    end

    command = text

    begin
      t = Thread.new do
        begin
          Thread.current[:dest] = dest
          Thread.current[:user] = user
          Thread.current[:command] = command
          Thread.current[:rules_file] = rules_file
          Thread.current[:typem] = typem
          if (dest[0] == "C") || (dest[0] == "G") and @rules_imported.key?(user.id) &&
            @rules_imported[user.id].key?(dchannel) && @bots_created.key?(@rules_imported[user.id][dchannel])
              Thread.current[:using_channel] = @rules_imported[user.id][dchannel]
          elsif dest[0] == "D" && @rules_imported.key?(user.id) && @rules_imported[user.id].key?(user.id) and
            @bots_created.key?(@rules_imported[user.id][user.id])
              Thread.current[:using_channel] = @rules_imported[user.id][user.id]
          else
              Thread.current[:using_channel] = ''
          end

          processed = process(user, command, dest, dchannel, rules_file, typem, files)
          @logger.info "command: #{nick}> #{command}" if processed
          on_demand = false
          if command.match(/^@?(#{config[:nick]}):*\s+(.+)/im) or
             command.match(/^()!(.+)/im) or
             command.match(/^()<@#{config[:nick_id]}>\s+(.+)/im)
            command = $2
            Thread.current[:command] = command
            on_demand = true
          end
          if @status == :on and
             (@questions.keys.include?(nick) or
              (@listening.include?(nick) and typem != :on_extended) or
              dest[0] == "D" or on_demand)
            @logger.info "command: #{nick}> #{command}" unless processed
            #todo: verify this

            if dest[0] == "C" or dest[0] == "G" or (dest[0] == "D" and typem == :on_call)
              if typem != :on_call and @rules_imported.key?(user.id) and @rules_imported[user.id].key?(dchannel)
                if @bots_created.key?(@rules_imported[user.id][dchannel])
                  if @bots_created[@rules_imported[user.id][dchannel]][:status] != :on
                    respond "The bot on that channel is not :on", dest
                    rules_file = ""
                  end
                end
              end
              unless rules_file.empty?
                begin
                  eval(File.new(config.path+rules_file).read) if File.exist?(config.path+rules_file)
                rescue Exception => stack
                  @logger.fatal "ERROR ON RULES FILE: #{rules_file}"
                  @logger.fatal stack
                end
                if defined?(rules)
                  command[0] = "" if command[0] == "!"
                  command.gsub!(/^@\w+:*\s*/, "")
                  if method(:rules).parameters.size == 4
                    rules(user, command, processed, dest)
                  elsif method(:rules).parameters.size == 5
                    rules(user, command, processed, dest, files)
                  else
                    rules(user, command, processed, dest, files, rules_file)
                  end
                else
                  @logger.warn "It seems like rules method is not defined"
                end
              end
            elsif @rules_imported.key?(user.id) and @rules_imported[user.id].key?(user.id)
              if @bots_created.key?(@rules_imported[user.id][user.id])
                if @bots_created[@rules_imported[user.id][user.id]][:status] == :on
                  begin
                    eval(File.new(config.path+rules_file).read) if File.exist?(config.path+rules_file)
                  rescue Exception => stack
                    @logger.fatal "ERROR ON imported RULES FILE: #{rules_file}"
                    @logger.fatal stack
                  end
                else
                  respond "The bot on <##{@rules_imported[user.id][user.id]}|#{@bots_created[@rules_imported[user.id][user.id]][:channel_name]}> is not :on", dest
                  rules_file = ""
                end
              end

              unless rules_file.empty?
                if defined?(rules)
                  command[0] = "" if command[0] == "!"
                  command.gsub!(/^@\w+:*\s*/, "")
                  if method(:rules).parameters.size == 4
                    rules(user, command, processed, dest)
                  elsif method(:rules).parameters.size == 5
                    rules(user, command, processed, dest, files)
                  else
                    rules(user, command, processed, dest, files, rules_file)
                  end
                else
                  @logger.warn "It seems like rules method is not defined"
                end
              end
            else
              @logger.info "it is a direct message with no rules file selected so no rules file executed."
              if command.match?(/^\s*bot\s+rules\s*$/i)
                respond "No rules running. You can use the command `use rules from CHANNEL` to specify the rules you want to use on this private conversation.\n`bot help` to see available commands.", dest
              end
              unless processed
                dont_understand('')
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
end
