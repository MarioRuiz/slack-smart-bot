class SlackSmartBot
  def treat_message(data)
    begin
      unless data.text.to_s.match(/\A\s*\z/)
        #to remove italic, bold... from data.text since there is no method on slack api
        #only works when no @user or #channel mentioned
        if !data.blocks.nil? and data.blocks.size > 0
          data.blocks.each do |b|
            if b.type == 'rich_text'
              if b.elements.size > 0
                b.elements.each do |e|
                  if e.type == 'rich_text_section'
                    if e.elements.size > 0 and e.elements.type.uniq == ['text']
                      data.text = e.elements.text.join
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
    rescue
      @logger.warn "Impossible to unescape or clean format for data.text:#{data.text}"
    end
    if config[:testing] and config.on_master_bot
      open("#{config.path}/buffer.log", "a") { |f|
        f.puts "|#{data.channel}|#{data.user}|#{data.text}"
      }
    end
    if data.channel[0] == "D" or data.channel[0] == "C" or data.channel[0] == "G" #Direct message or Channel or Private Channel
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
      if data.text.match(/^<@#{config[:nick_id]}>\s(on\s)?<#(\w+)\|([^>]+)>\s*:?\s*(.*)/im)
        channel_rules = $2
        channel_rules_name = $3
        # to be treated only on the bot of the requested channel
        if @channel_id == channel_rules
          data.text = $4
          typem = :on_call
        end
      elsif dest == @master_bot_id
        if config.on_master_bot #only to be treated on master bot channel
          typem = :on_master
        end
      elsif @bots_created.key?(dest)
        if @channel_id == dest #only to be treated by the bot on the channel
          typem = :on_bot
        end
      elsif dest[0] == "D" #Direct message
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
      elsif dest[0] == "C" or dest[0] == "G"
        #only to be treated on the channel of the bot. excluding running ruby
        if !config.on_master_bot and @bots_created.key?(@channel_id) and @bots_created[@channel_id][:extended].include?(@channels_name[dest]) and
           !data.text.match?(/^!?\s*(ruby|code)\s+/) and !data.text.match?(/^!?!?\s*(ruby|code)\s+/) and !data.text.match?(/^\^?\s*(ruby|code)\s+/)
          typem = :on_extended
        elsif config.on_master_bot and (data.text.match?(/^!?\s*(ruby|code)\s+/) or data.text.match?(/^!?!?\s*(ruby|code)\s+/) or data.text.match?(/^\^?\s*(ruby|code)\s+/)  )
          #or in case of running ruby, the master bot
          @bots_created.each do |k, v|
            if v.key?(:extended) and v[:extended].include?(@channels_name[dest])
              typem = :on_extended
              break
            end
          end
        end
        if dest[0] == "G" and config.on_master_bot and typem != :on_extended #private group
          typem = :on_pg
        end
      end
    end
    unless typem == :dont_treat
      begin
        #todo: when changed @questions user_id then move user_info inside the ifs to avoid calling it when not necessary
        user_info = client.web_client.users_info(user: data.user)

        if @questions.key?(user_info.user.name)
          if data.text.match?(/^\s*(Bye|Bæ|Good\sBye|Adiós|Ciao|Bless|Bless\sBless|Adeu)\s(#{@salutations.join("|")})\s*$/i)
            @questions.delete(user_info.user.name)
            command = data.text
          else
            command = @questions[user_info.user.name]
            @questions[user_info.user.name] = data.text
          end
        else
          command = data.text
        end

        #when added special characters on the message
        if command.size >= 2 and
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
          channels = client.web_client.conversations_list(
            types: "private_channel,public_channel",
            limit: "1000",
            exclude_archived: "true",
          ).channels
          channel_found = channels.detect { |c| c.name == channel_rules_name }
          members = client.web_client.conversations_members(channel: @channels_id[channel_rules_name]).members unless channel_found.nil?
          if channel_found.nil?
            @logger.fatal "Not possible to find the channel #{channel_rules_name}"
          elsif channel_found.name == config.master_channel
            respond "You cannot use the rules from Master Channel on any other channel.", dest
          elsif @status != :on
            respond "The bot in that channel is not :on", dest
          elsif data.user == channel_found.creator or members.include?(data.user)
            process_first(user_info.user, command, dest, channel_rules, typem, data.files, data.ts, data.thread_ts)
          else
            respond "You need to join the channel <##{channel_found.id}> to be able to use the rules.", dest
          end
        elsif config.on_master_bot and typem == :on_extended and
              command.size > 0 and command[0] != "-"
          # to run ruby only from the master bot for the case more than one extended
          process_first(user_info.user, command, dest, @channel_id, typem, data.files, data.ts, data.thread_ts)
        elsif !config.on_master_bot and @bots_created[@channel_id].key?(:extended) and
              @bots_created[@channel_id][:extended].include?(@channels_name[data.channel]) and
              command.size > 0 and command[0] != "-"
          process_first(user_info.user, command, dest, @channel_id, typem, data.files, data.ts, data.thread_ts)
        elsif (dest[0] == "D" or @channel_id == data.channel or data.user == config[:nick_id]) and
              command.size > 0 and command[0] != "-"
          process_first(user_info.user, command, dest, data.channel, typem, data.files, data.ts, data.thread_ts)
          # if @botname on #channel_rules: do something
        end
      rescue Exception => stack
        @logger.fatal stack
      end
    else
      if !config.on_master_bot and !dest.nil? and (dest == @master_bot_id or dest[0] == "D") and
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
        end
      end
    end
  end
end
