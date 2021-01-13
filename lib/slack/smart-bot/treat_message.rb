class SlackSmartBot
  def treat_message(data, remove_blocks = true)

    begin
      unless data.text.to_s.match(/\A\s*\z/)
        #to remove italic, bold... from data.text since there is no method on slack api
        #only works when no @user or #channel mentioned
        if remove_blocks and !data.blocks.nil? and data.blocks.size > 0
          data.blocks.each do |b|
            if b.type == 'rich_text'
              if b.elements.size > 0
                b.elements.each do |e|
                  if e.type == 'rich_text_section'
                    if e.elements.size > 0 and (e.elements.type.uniq - ['link', 'text']) == []
                      data.text = ''
                      e.elements.each do |el|
                        if el.type == 'text'
                          data.text += el.text
                        else
                          data.text += el.url
                        end
                      end
                    end
                    break
                  end
                end
              end
              break
            end
          end
        end
        data.text = CGI.unescapeHTML(data.text)
        data.text.gsub!("\u00A0", " ") #to change &nbsp; (asc char 160) into blank space
      end
      data.text.gsub!('‘', "'")
      data.text.gsub!('’', "'")
      data.text.gsub!('“', '"') 
      data.text.gsub!('”', '"')
    rescue
      @logger.warn "Impossible to unescape or clean format for data.text:#{data.text}"
    end
    data.routine = false unless data.key?(:routine)

    if config[:testing] and config.on_master_bot
      open("#{config.path}/buffer.log", "a") { |f|
        f.puts "|#{data.channel}|#{data.user}|#{data.user_name}|#{data.text}"
      }
    end
    if data.key?(:dest) and data.dest.to_s!='' # for run routines and publish on different channels
      dest = data.dest
    elsif data.channel[0] == "D" or data.channel[0] == "C" or data.channel[0] == "G" #Direct message or Channel or Private Channel
      dest = data.channel
    else # not treated
      dest = nil
    end
    #todo: sometimes data.user is nil, check the problem.
    @logger.warn "!dest is nil. user: #{data.user}, channel: #{data.channel}, message: #{data.text}" if dest.nil?
    if !data.files.nil? and data.files.size == 1 and data.text.to_s == "" and data.files[0].filetype == "ruby"
      data.text = "ruby"
    end
    if !dest.nil? and config.on_master_bot and !data.text.nil? and data.text.match(/^ping from (.+)\s*$/) and data.user == config[:nick_id]
      @pings << $1
    end
    typem = :dont_treat
    if !dest.nil? and !data.text.nil? and !data.text.to_s.match?(/^\s*$/)
      #if data.text.match(/^\s*<@#{config[:nick_id]}>\s+(on\s+)?<#(\w+)\|([^>]+)>\s*:?\s*(.*)/im)
      if data.text.match(/^\s*<@#{config[:nick_id]}>\s+(on\s+)?((<#\w+\|[^>]+>\s*)+)\s*:?\s*(.*)/im)
        channels_rules = $2 #multiple channels @smart-bot on #channel1 #channel2 echo AAA
        data_text = $4
        channel_rules_name = ''
        channel_rules = ''
        # to be treated only on the bots of the requested channels
        channels_rules.scan(/<#(\w+)\|([^>]+)>/).each do |tcid, tcname|
          if @channel_id == tcid
            data.text = data_text
            typem = :on_call
            channel_rules = tcid
            channel_rules_name = tcname
            break
          end
        end
      elsif data.channel == @master_bot_id
        if config.on_master_bot #only to be treated on master bot channel
          typem = :on_master
        end
      elsif @bots_created.key?(data.channel)
        if @channel_id == data.channel #only to be treated by the bot on the channel
          typem = :on_bot
        end
      elsif data.channel[0] == "D" #Direct message
        get_rules_imported()
        if @rules_imported.key?(data.user) && @rules_imported[data.user].key?(data.user) and
          @bots_created.key?(@rules_imported[data.user][data.user])
          if @channel_id == @rules_imported[data.user][data.user]
            #only to be treated by the channel we are 'using'
            typem = :on_dm
          end
        elsif config.on_master_bot
          #only to be treated by master bot
          typem = :on_dm
        end
      elsif data.channel[0] == "C" or data.channel[0] == "G"
        #only to be treated on the channel of the bot. excluding running ruby
        if !config.on_master_bot and @bots_created.key?(@channel_id) and @bots_created[@channel_id][:extended].include?(@channels_name[data.channel]) and
           !data.text.match?(/^!?\s*(ruby|code)\s+/) and !data.text.match?(/^!?!?\s*(ruby|code)\s+/) and !data.text.match?(/^\^?\s*(ruby|code)\s+/)
          typem = :on_extended
        elsif config.on_master_bot and (data.text.match?(/^!?\s*(ruby|code)\s+/) or data.text.match?(/^!?!?\s*(ruby|code)\s+/) or data.text.match?(/^\^?\s*(ruby|code)\s+/)  )
          #or in case of running ruby, the master bot
          @bots_created.each do |k, v|
            if v.key?(:extended) and v[:extended].include?(@channels_name[data.channel])
              typem = :on_extended
              break
            end
          end
        end
        if data.channel[0] == "G" and config.on_master_bot and typem != :on_extended #private group
          typem = :on_pg
        end
      end
    end
    unless typem == :dont_treat
      if (Time.now - @last_activity_check) > 60 * 30 #every 30 minutes
        @last_activity_check = Time.now
        @listening.each do |k,v|
          v.each do |kk, vv|
            @listening[k].delete(kk) if (Time.now - vv) > 60 * 30
          end
          @listening.delete(k) if @listening[k].empty?
        end
      end
      begin
        #todo: when changed @questions user_id then move user_info inside the ifs to avoid calling it when not necessary
        user_info = get_user_info(data.user)

        #user_info.user.id = data.user #todo: remove this line when slack issue with Wxxxx Uxxxx fixed
        data.user = user_info.user.id  #todo: remove this line when slack issue with Wxxxx Uxxxx fixed
        if data.thread_ts.nil?
          qdest = dest
        else
          qdest = data.thread_ts
        end
        if !answer(user_info.user.name, qdest).empty?
          if data.text.match?(/^\s*(Bye|Bæ|Good\sBye|Adiós|Ciao|Bless|Bless\sBless|Adeu)\s(#{@salutations.join("|")})\s*$/i)
            answer_delete(user_info.user.name, qdest)
            command = data.text
          else
            command = answer(user_info.user.name, qdest)
            @answer[user_info.user.name][qdest] = data.text
            @questions[user_info.user.name] = data.text # to be backwards compatible #todo remove it when 2.0
          end
        elsif @repl_sessions.key?(user_info.user.name) and data.channel==@repl_sessions[user_info.user.name][:dest] and 
          ((@repl_sessions[user_info.user.name][:on_thread] and data.thread_ts == @repl_sessions[user_info.user.name][:thread_ts]) or
           (!@repl_sessions[user_info.user.name][:on_thread] and data.thread_ts.to_s == '' ))
          
          if data.text.match(/^\s*```(.*)```\s*$/im)
              @repl_sessions[user_info.user.name][:command] = $1
          else   
            @repl_sessions[user_info.user.name][:command] = data.text
          end
          command = 'repl'
        else
          command = data.text
        end

        #when added special characters on the message
        if command.match(/^\s*```(.*)```\s*$/im)
          command = $1
        elsif command.size >= 2 and
           ((command[0] == "`" and command[-1] == "`") or (command[0] == "*" and command[-1] == "*") or (command[0] == "_" and command[-1] == "_"))
          command = command[1..-2]
        end

        #ruby file attached
        if !data.files.nil? and data.files.size == 1 and
           (command.match?(/^(ruby|code)\s*$/) or (command.match?(/^\s*$/) and data.files[0].filetype == "ruby") or
            (typem == :on_call and data.files[0].filetype == "ruby"))
          res = Faraday.new("https://files.slack.com", headers: { "Authorization" => "Bearer #{config[:token]}" }).get(data.files[0].url_private)
          command += " ruby" if command != "ruby"
          command = "#{command} #{res.body.to_s.force_encoding("UTF-8")}"
        end

        if typem == :on_call
          command = "!" + command unless command[0] == "!" or command.match?(/^\s*$/) or command[0] == "^"

          #todo: add pagination for case more than 1000 channels on the workspace
          channels = get_channels()
          channel_found = channels.detect { |c| c.name == channel_rules_name }
          members = get_channel_members(@channels_id[channel_rules_name]) unless channel_found.nil?
          if channel_found.nil?
            @logger.fatal "Not possible to find the channel #{channel_rules_name}"
          elsif channel_found.name == config.master_channel
            respond "You cannot use the rules from Master Channel on any other channel.", data.channel
          elsif @status != :on
            respond "The bot in that channel is not :on", data.channel
          elsif data.user == channel_found.creator or members.include?(data.user)
            process_first(user_info.user, command, dest, channel_rules, typem, data.files, data.ts, data.thread_ts, data.routine)
          else
            respond "You need to join the channel <##{channel_found.id}> to be able to use the rules.", data.channel
          end
        elsif config.on_master_bot and typem == :on_extended and
              command.size > 0 and command[0] != "-"
          # to run ruby only from the master bot for the case more than one extended
          process_first(user_info.user, command, dest, @channel_id, typem, data.files, data.ts, data.thread_ts, data.routine)
        elsif !config.on_master_bot and @bots_created[@channel_id].key?(:extended) and
              @bots_created[@channel_id][:extended].include?(@channels_name[data.channel]) and
              command.size > 0 and command[0] != "-"
          process_first(user_info.user, command, dest, @channel_id, typem, data.files, data.ts, data.thread_ts, data.routine)
        elsif (dest[0] == "D" or @channel_id == data.channel or data.user == config[:nick_id]) and
              command.size > 0 and command[0] != "-"
          process_first(user_info.user, command, dest, data.channel, typem, data.files, data.ts, data.thread_ts, data.routine)
          # if @botname on #channel_rules: do something
        end
      rescue Exception => stack
        @logger.fatal stack
      end
    else
      if !config.on_master_bot and !dest.nil? and (data.channel == @master_bot_id or dest[0] == "D") and
         data.text.match?(/^\s*bot\s+status\s*$/i) and @admin_users_id.include?(data.user)
        respond "ping from #{config.channel}", dest
      elsif !config.on_master_bot and !dest.nil? and data.user == config[:nick_id] and dest == @master_bot_id
        # to treat on other bots the status messages populated on master bot
        case data.text
        when /^Bot has been (closed|killed) by/i
          sleep 2
          get_bots_created()
        when /^Changed status on (.+) to :(.+)/i
          sleep 2
          get_bots_created()
        when /extended the rules from (.+) to be used on (.+)\.$/i
          sleep 2
          get_bots_created()
        when /removed the access to the rules of (.+) from (.+)\.$/i
          sleep 2
          get_bots_created()
        when /global shortcut added/
          sleep 2
          if File.exist?("#{config.path}/shortcuts/shortcuts_global.rb")
            file_sc = IO.readlines("#{config.path}/shortcuts/shortcuts_global.rb").join
            unless file_sc.to_s() == ""
              @shortcuts_global = eval(file_sc)
            end
          end
        when /global shortcut deleted/
          sleep 2
          if File.exist?("#{config.path}/shortcuts/shortcuts_global.rb")
            file_sc = IO.readlines("#{config.path}/shortcuts/shortcuts_global.rb").join
            unless file_sc.to_s() == ""
              @shortcuts_global = eval(file_sc)
            end
          end
        end
      end
    end
  end
end
