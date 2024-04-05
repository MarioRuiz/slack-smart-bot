class SlackSmartBot

    # helpadmin: ----------------------------------------------
    # helpadmin: `send message to @USER_NAME : MESSAGE`
    # helpadmin: `send message to #CHANNEL_NAME : MESSAGE`
    # helpadmin: `send message to THREAD_ID : MESSAGE`
    # helpadmin: `send message to URL : MESSAGE`
    # helpadmin: `send message to @USER1 @USER99 : MESSAGE`
    # helpadmin: `send message to #CHANNEL1 #CHANNEL99 : MESSAGE`
    # helpadmin: `send message to users from YYYY/MM/DD to YYYY/MM/DD #CHANNEL COMMAND_ID: MESSAGE`
    # helpadmin:    It will send the specified message as SmartBot
    # helpadmin:    You can use this command only if you are a Master admin user and if you are in a private conversation with the bot
    # helpadmin:    In case from and to specified will send a DM to all users that have been using the SmartBot according to the SmartBot Stats. One message every 5sc. #CHANNEL and COMMAND_ID are optional filters.
    # helpadmin: command_id: :send_message
    # helpadmin:
    def send_message(dest, user, typem, to, thread_ts, stats_from, stats_to, stats_channel_filter, stats_command_filter, message)
      save_stats(__method__)
      if config.team_id_masters.include?("#{user.team_id}_#{user.name}") and typem==:on_dm #master admin user
        react :runner
        unless Thread.current[:command_orig].to_s == ''
          message_orig = Thread.current[:command_orig].to_s.gsub("\u00A0", " ").scan(/[^:]+\s*:\s+(.+)/im).join
          message = message_orig unless message_orig == ''
        end
        succ = true
        if stats_from!='' and stats_to!=''
          users = []
          user_ids = []
          stats_from.gsub!('/', '-')
          stats_to.gsub!('/', '-')
          stats_from += " 00:00:00 +0000"
          stats_to += " 23:59:59 +0000"
          Dir["#{config.stats_path}.*.log"].sort.each do |file|
            if file >= "#{config.stats_path}.#{stats_from[0..6]}.log" and file <= "#{config.stats_path}.#{stats_to[0..6]}.log"
              CSV.foreach(file, headers: true, header_converters: :symbol, converters: :numeric) do |row|
                if row[:date] >= stats_from and row[:date] <= stats_to and !users.include?(row[:user_name])
                  if (stats_channel_filter=='' and stats_command_filter=='') or
                    (stats_channel_filter!='' and stats_command_filter=='' and (row[:bot_channel_id]==stats_channel_filter or row[:dest_channel_id]==stats_channel_filter)) or
                    (stats_command_filter!='' and stats_channel_filter=='' and row[:command]==stats_command_filter) or
                    (stats_channel_filter!='' and stats_command_filter!='' and ((row[:bot_channel_id]==stats_channel_filter or row[:dest_channel_id]==stats_channel_filter) and row[:command]==stats_command_filter))

                    user_ids << row[:user_id]
                    users << row[:user_name]
                  end
                end
              end
            end
          end

          users_success = []
          users_failed = []

          user_ids.each do |u|
            @buffered = false if config.testing
            succ = (respond message, u, thread_ts: thread_ts, web_client: true)
            if succ
              users_success << u
            else
              users_failed << u
            end
            sleep 5
          end
          respond "Users that received the message (#{users_success.size}): <@#{users_success.join('>, <@')}>", dest if users_success.size > 0
          respond "Users that didn't receive the message (#{users_failed.size}): <@#{users_failed.join('>, <@')}>", dest if users_failed.size > 0
          respond "No users selected to send the message.", dest if users_success.size == 0 and users_failed.size == 0
          succ = false if users_failed.size > 0
        else
          to.each do |t|
            unless t.match?(/^\s*$/)
              @buffered = false if config.testing
              succ = (respond message, t, thread_ts: thread_ts, web_client: true) && succ
            end
          end
        end
        unreact :runner
        if succ
          react :heavy_check_mark
        else
          react :x
        end
      else
        respond "Only master admin users on a private conversation with the SmartBot can send messages as SmartBot.", dest
      end
    end
end
