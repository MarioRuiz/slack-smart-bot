class SlackSmartBot
  def treat_message(data, remove_blocks = true)
    @buffered = false if config[:testing]
    begin
      begin
        command_orig = data.text
        unless data.text.to_s.match(/\A\s*\z/)
          #to remove italic, bold... from data.text since there is no method on slack api
          if remove_blocks and !data.blocks.nil? and data.blocks.size > 0
            data_text = ""
            data.blocks.each do |b|
              if b.type == "rich_text"
                if b.elements.size > 0
                  b.elements.each do |e|
                    if e.type == "rich_text_section" or e.type == "rich_text_preformatted"
                      if e.elements.size > 0 and (e.elements.type.uniq - ["link", "text", "user", "channel"]) == []
                        data_text += "```" if e.type == "rich_text_preformatted"
                        e.elements.each do |el|
                          if el.type == "text"
                            data_text += el.text
                          elsif el.type == "user"
                            data_text += "<@#{el.user_id}>"
                          elsif el.type == "channel"
                            tch = data.text.scan(/(<##{el.channel_id}\|[^\>]*>)/).flatten.first
                            data_text += tch.to_s
                          else
                            data_text += el.url
                          end
                        end
                        data_text += "```" if e.type == "rich_text_preformatted"
                      end
                    end
                  end
                end
              end
            end
            data.text = data_text unless data_text == ""
          end
          data.text = CGI.unescapeHTML(data.text)
          data.text.gsub!("\u00A0", " ") #to change &nbsp; (asc char 160) into blank space
        end
        data.text.gsub!("‘", "'")
        data.text.gsub!("’", "'")
        data.text.gsub!("“", '"')
        data.text.gsub!("”", '"')
      rescue Exception => exc
        @logger.warn "Impossible to unescape or clean format for data.text:#{data.text}"
        @logger.warn exc.inspect
      end

      unless data.key?(:routine)
        data.routine = false
        data.routine_name = ""
        data.routine_type = ""
      end
      if config[:testing] and config.on_master_bot and !@buffered
        @buffered = true
        open("#{config.path}/buffer.log", "a") { |f|
          f.puts "|#{data.channel}|#{data.thread_ts}|#{data.user}|#{data.user_name}|#{data.text}"
        }
      end

      if data.key?(:dest) and data.dest.to_s != "" # for run routines and publish on different channels
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

      #open ai chat gpt and shared messages as an input
      if data.text.match?(/\A\s*(^|!!|!)?\s*(\?|\?\?)\s*/im) and !data.attachments.nil? and data.attachments.size > 0 and !data.attachments[0].text.nil? and data.attachments[0].text != ""
        data.attachments.each_with_index do |att, i|
          if !att.text.nil? and att.text != ""
            data.text += "\n#{att.text}"
          end
        end
      end
      if !dest.nil? and config.on_master_bot and !data.text.nil? and data.text.match(/^ping from (.+)\s*$/) and data.user == config[:nick_id]
        @pings << $1
      end

      if config.on_master_bot and @vacations_check != Time.now.strftime("%Y%m%d%H") #every hour since depends on user's time zone
        @vacations_check = Time.now.strftime("%Y%m%d%H")
        t = Thread.new do
          check_vacations(date: nil, only_first_day: true)
        end
      end
      typem = :dont_treat

      @users = get_users() if @users.empty?
      if data.key?(:bot_id) and data.bot_id.to_s != ""
        if @slack_bots.key?(data.bot_id) #bot or workflow
          data.user = @slack_bots[data.bot_id]
        else
          bot_info = get_user_info(data.bot_id, is_bot: true)
          if bot_info.nil? or bot_info.empty?
            @logger.warn "Bot not found on users with data: #{data.inspect}"
          else
            @slack_bots[data.bot_id] = bot_info.user.id
            data.user = bot_info.user.id
            @users << bot_info.user unless bot_info.nil? or bot_info.empty?
          end
        end
      end

      if data.nil? or data.user.nil? or data.user.to_s == ""
        user_info = nil
      else
        user_info = find_user(data.user, get_sso_user_name: true)
        if user_info.nil?
          @logger.warn "User not found on users with id #{data.user} and user_team #{data.user_team}"
        elsif !user_info.key?(:team_id) or user_info.team_id.to_s.empty?
          @logger.warn "User with id #{data.user} and user_team #{data.user_team} has no team_id. User_info: #{user_info.inspect}"
        end
      end
      if !dest.nil? and !data.text.nil? and !data.text.to_s.match?(/\A\s*\z/)
        get_bots_created()
        if data.channel[0] == "D" and !data.text.to_s.match?(/^\s*<@#{config[:nick_id]}>\s+/) and
           (data.text.to_s.match?(/^\s*(on)?\s*<#\w+\|[^>]*>/i) or data.text.to_s.match?(/^\s*(on)?\s*#\w+/i))
          data.text = "<@#{config[:nick_id]}> " + data.text.to_s
        end
        #todo: we need to add mixed channels: @smart-bot on private1 #bot1cm <#CXDDFRDDF|bot2cu>: echo A
        if data.text.match(/\A\^\^+/) # to open a thread it will be only when starting by single ^
          typem = :dont_treat
        elsif data.text.match(/^\s*<@#{config[:nick_id]}>\s+(on\s+)?((<#\w+\|[^>]*>\s*)+)\s*:?\s*(.*)/im) or
              data.text.match(/^\s*<@#{config[:nick_id]}>\s+(on\s+)?((#[a-zA-Z0-9\-\_]+\s*)+)\s*:?\s*(.*)/im) or
              data.text.match(/^\s*<@#{config[:nick_id]}>\s+(on\s+)?(([a-zA-Z0-9\-\_]+\s*)+)\s*:\s*(.*)/im)
          channels_rules = $2 #multiple channels @smart-bot on #channel1 #channel2 echo AAA
          data_text = $4
          channel_rules_name = ""
          channel_rules = ""
          channels_arr = channels_rules.scan(/<#(\w+)\|([^>]*)>/)
          if channels_arr.size == 0
            channels_arr = []
            channels_rules.scan(/([^\s]+)/).each do |cn|
              cna = cn.join.gsub("#", "")
              if @channels_name.key?(cna)
                channels_arr << [cna, @channels_name[cna]]
              else
                channels_arr << [@channels_id[cna], cna]
              end
            end
          else
            channels_arr.each do |row|
              row[0] = @channels_id[row[1]] if row[0] == ""
              row[1] = @channels_name[row[0]] if row[1] == ""
            end
          end

          # to be treated only on the bots of the requested channels
          channels_arr.each do |tcid, tcname|
            if @channel_id == tcid
              data.text = data_text
              typem = :on_call
              channel_rules = tcid
              channel_rules_name = tcname
              break
            elsif @bots_created.key?(@channel_id) and @bots_created[@channel_id][:extended].include?(tcname)
              data.text = data_text
              typem = :on_call
              channel_rules = @channel_id
              channel_rules_name = @channels_name[@channel_id]
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
          if @rules_imported.key?("#{user_info.team_id}_#{user_info.name}") && @rules_imported["#{user_info.team_id}_#{user_info.name}"].key?(user_info.name) and
             @bots_created.key?(@rules_imported["#{user_info.team_id}_#{user_info.name}"][user_info.name])
            if @channel_id == @rules_imported["#{user_info.team_id}_#{user_info.name}"][user_info.name]
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
          elsif config.on_master_bot and (data.text.match?(/^!?\s*(ruby|code)\s+/) or data.text.match?(/^!?!?\s*(ruby|code)\s+/) or data.text.match?(/^\^?\s*(ruby|code)\s+/))
            #or in case of running ruby, the master bot
            @bots_created.each do |k, v|
              if v.key?(:extended) and v[:extended].include?(@channels_name[data.channel])
                typem = :on_extended
                break
              end
            end
          end
          extended = false
          @bots_created.each do |k, v|
            if v.key?(:extended) and v[:extended].include?(@channels_name[data.channel])
              extended = true
              break
            end
          end
          if data.channel[0] == "G" and config.on_master_bot and !extended #private group
            typem = :on_pg
          elsif data.channel[0] == "C" and config.on_master_bot and !extended #public group
            typem = :on_pub
          end
        end
      end
      load "#{config.path}/rules/general_commands.rb" if File.exist?("#{config.path}/rules/general_commands.rb") and @datetime_general_commands != File.mtime("#{config.path}/rules/general_commands.rb")
      eval(File.new(config.path + config.rules_file).read) if !defined?(rules) and File.exist?(config.path + config.rules_file) and !config.rules_file.empty?
      unless typem == :dont_treat or user_info.nil?
        if (Time.now - @last_activity_check) > TIMEOUT_LISTENING #every 30 minutes
          @last_activity_check = Time.now
          @listening.each do |k, v|
            unless k == :threads
              v.each do |kk, vv|
                if (Time.now - vv) > TIMEOUT_LISTENING
                  if @listening[:threads].key?(kk) && @active_chat_gpt_sessions.key?(k) &&
                     @active_chat_gpt_sessions[k].key?(kk)
                    unreact :running, kk, channel: @listening[:threads][kk]
                    session_name = @active_chat_gpt_sessions[k][kk]
                    chatgpt_message = ":information_source: ChatGPT session has been terminated due to inactivity."
                    if !session_name.to_s.empty?
                      chatgpt_message += "\n\nIf you want to start it again on this thread call `chatgpt #{session_name}`"
                    end
                    respond chatgpt_message, @listening[:threads][kk], thread_ts: kk
                    @listening[:threads].delete(kk)
                  end
                  @listening[k].delete(kk)
                end
              end
              @listening.delete(k) if @listening[k].empty?
            end
          end
        end
        begin
          #user_info.id = data.user #todo: remove this line when slack issue with Wxxxx Uxxxx fixed
          data.user = user_info.id  #todo: remove this line when slack issue with Wxxxx Uxxxx fixed
          team_id_user = "#{user_info.team_id}_#{user_info.name}"
          if data.thread_ts.to_s.empty?
            qdest = dest
          else
            qdest = data.thread_ts
          end
          if !answer(user_info, qdest).empty?
            if data.text.match?(/\A\s*(Bye|Bæ|Good\sBye|Adiós|Ciao|Bless|Bless\sBless|Adeu)\s(#{@salutations.join("|")})\s*$/i)
              answer_delete(user_info, qdest)
              command = data.text
            else
              command = answer(user_info, qdest)
              @answer[team_id_user][qdest] = data.text
              @questions[team_id_user] = data.text # to be backwards compatible #todo remove it when 2.0
            end
          elsif @repl_sessions.key?(team_id_user) and data.channel == @repl_sessions[team_id_user][:dest] and
                ((@repl_sessions[team_id_user][:on_thread] and data.thread_ts == @repl_sessions[team_id_user][:thread_ts]) or
                 (!@repl_sessions[team_id_user][:on_thread] and data.thread_ts.to_s == ""))
            if data.text.match(/^\s*```(.*)```\s*$/im)
              @repl_sessions[team_id_user][:command] = $1
            else
              @repl_sessions[team_id_user][:command] = data.text
            end
            command = "repl"
          else
            command = data.text
          end
          #when added special characters on the message
          if command.match(/\A\s*```(.*)```\s*\z/im)
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
              process_first(user_info, command, dest, channel_rules, typem, data.files, data.ts, data.thread_ts, data.routine, data.routine_name, data.routine_type, command_orig)
            else
              respond "You need to join the channel <##{channel_found.id}> to be able to use the rules.", data.channel
            end
          elsif config.on_master_bot and typem == :on_extended and
                command.size > 0 and command[0] != "-"
            # to run ruby only from the master bot for the case more than one extended
            process_first(user_info, command, dest, @channel_id, typem, data.files, data.ts, data.thread_ts, data.routine, data.routine_name, data.routine_type, command_orig)
          elsif !config.on_master_bot and @bots_created[@channel_id].key?(:extended) and
                @bots_created[@channel_id][:extended].include?(@channels_name[data.channel]) and
                command.size > 0 and command[0] != "-"
            process_first(user_info, command, dest, @channel_id, typem, data.files, data.ts, data.thread_ts, data.routine, data.routine_name, data.routine_type, command_orig)
          elsif (dest[0] == "D" or @channel_id == data.channel or data.user == config[:nick_id]) and
                command.size > 0 and command[0] != "-"
            process_first(user_info, command, dest, data.channel, typem, data.files, data.ts, data.thread_ts, data.routine, data.routine_name, data.routine_type, command_orig)
            # if @botname on #channel_rules: do something
          elsif (typem == :on_pub or typem == :on_pg) and command.size > 0 and command[0] != "-"
            process_first(user_info, command, dest, channel_rules, typem, data.files, data.ts, data.thread_ts, data.routine, data.routine_name, data.routine_type, command_orig)
          end
        rescue Exception => stack
          @logger.fatal stack
        end
      else
        if user_info.nil? and data.user.to_s != ""
          @logger.warn "Pay attention there is no user on users with id #{data.user}"
        end
        if !config.on_master_bot and !dest.nil? and (data.channel == @master_bot_id or dest[0] == "D") and
           data.text.match?(/^\s*(!|!!|\^)?\s*bot\s+status\s*$/i) and @admin_users_id.include?(data.user)
          respond "ping from #{config.channel}", dest
        elsif !config.on_master_bot and !dest.nil? and data.user == config[:nick_id] and dest == @master_bot_id
          # to treat on other bots the status messages populated on master bot
          case data.text
          when /General message has been set\./i, /General message won't be displayed anymore./i
            sleep 2
            if File.exist?("#{config.path}/config_tmp.status")
              file_cts = IO.readlines("#{config.path}/config_tmp.status").join
              unless file_cts.to_s() == ""
                file_cts = eval(file_cts)
                if file_cts.is_a?(Hash) and file_cts.key?(:general_message)
                  config.general_message = file_cts.general_message
                end
              end
            end
          when /From now on I'll be on maintenance status/i
            sleep 2
            if File.exist?("#{config.path}/config_tmp.status")
              file_cts = IO.readlines("#{config.path}/config_tmp.status").join
              unless file_cts.to_s() == ""
                file_cts = eval(file_cts)
                if file_cts.is_a?(Hash) and file_cts.key?(:on_maintenance)
                  config.on_maintenance = file_cts.on_maintenance
                  config.on_maintenance_message = file_cts.on_maintenance_message
                end
              end
            end
          when /From now on I won't be on maintenance/i
            sleep 2
            if File.exist?("#{config.path}/config_tmp.status")
              file_cts = IO.readlines("#{config.path}/config_tmp.status").join
              unless file_cts.to_s() == ""
                file_cts = eval(file_cts)
                if file_cts.is_a?(Hash) and file_cts.key?(:on_maintenance)
                  config.on_maintenance = file_cts.on_maintenance
                  config.on_maintenance_message = file_cts.on_maintenance_message
                end
              end
            end
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
            if File.exist?("#{config.path}/shortcuts/shortcuts_global.yaml")
              @shortcuts_global = YAML.load(File.read("#{config.path}/shortcuts/shortcuts_global.yaml"))
            end
          when /global shortcut deleted/
            sleep 2
            if File.exist?("#{config.path}/shortcuts/shortcuts_global.yaml")
              @shortcuts_global = YAML.load(File.read("#{config.path}/shortcuts/shortcuts_global.yaml"))
            end
          when /\AGame\s+over!\z/i
            sleep 2
            get_bots_created()
            if File.exist?("#{config.path}/config_tmp.status")
              file_cts = IO.readlines("#{config.path}/config_tmp.status").join
              unless file_cts.to_s() == ""
                file_cts = eval(file_cts)
                if file_cts.is_a?(Hash) and file_cts.key?(:exit_bot)
                  config.exit_bot = file_cts.exit_bot
                end
                @status = :exit if config.exit_bot
              end
            end
            if @status == :exit
              @listening[:threads].each do |thread_ts, channel_thread|
                unreact :running, thread_ts, channel: channel_thread
                respond "ChatGPT session closed since SmartBot is going to be closed.\nCheck <##{@channels_id[config.status_channel]}>", channel_thread, thread_ts: thread_ts
              end
              @logger.info "Game over!"
              sleep 3
              exit!
            end
          end
        end
      end
      unless data.nil? or data.channel.nil? or data.channel.empty?
        @announcements_activity_after[data.channel] ||= 0
        @announcements_activity_after[data.channel] += 1
      end
    rescue Exception => stack
      @logger.fatal stack
    end
  end
end
