class SlackSmartBot

  #todo: add tests
  def recap(user, dest, channel, date_start, date_end, my_recap)
    save_stats(__method__)

    require "date"
    require "time"
    react :runner
    @history_still_running ||= false

    if channel[0] == "D"
      messages = []
      messages << "Sorry, `recap` command is not available in direct messages."
      messages << "Specify a channel instead or call it from a channel."
      messages << "For example: `my recap 2023 #channel`"
      messages << ""
      messages << "You can also call from a DM:"
      messages << "\t\t`bot stats last year`"
      messages << "\t\t`bot stats last year monthly graph`"
      messages << "\t\t`bot stats`"
      messages << ""
      messages << "Call `bot help bot stats` for more information."
      respond messages.join("\n")
    elsif @history_still_running
      respond "Due to Slack API rate limit, `recap` command is limited. Waiting for other `recap` command to finish."
      num_times = 0
      while @history_still_running and num_times < 30
        num_times += 1
        sleep 1
      end
      if @history_still_running
        respond "Sorry, Another `recap` command is still running after 30 seconds. Please try again later."
      end
    end

    if !@history_still_running and channel[0] != "D"
      @history_still_running = true
      begin
        date_start = date_start.gsub(".", "/").gsub("-", "/")
        date_end = date_end.gsub(".", "/").gsub("-", "/")
        if date_start.to_s == ""
          date_start = Date.today.strftime("%Y/01/01")
        elsif date_start.match(/^\d\d\d\d$/)
          date_start = "#{date_start}/01/01"
        end
        if date_end.to_s == ""
          date_end = Date.parse(date_start).strftime("%Y/12/31")
        end
        if date_end < date_start
          respond "Sorry, `recap` command requires `date_start` to be before `date_end`."
        else
          # if more than one year respond max one year
          num_days = (Date.parse(date_end) - Date.parse(date_start)).to_i
          if num_days > 365
            respond "Sorry, `recap` command is limited to one year."
          else
            messages = []
            #if date_start is 1st of January and date_end is 31st of December, then use the year only
            if Date.parse(date_start).strftime("%m/%d") == "01/01" and Date.parse(date_end).strftime("%m/%d") == "12/31"
              messages << "*#{Date.parse(date_start).strftime("%Y")} Recap <##{channel}>*"
            else
              messages << "*Recap for <##{channel}> from #{date_start} to #{date_end}*"
            end
            date_start = date_start + " 00:00:00"
            date_start = Time.strptime(date_start, "%Y/%m/%d %H:%M:%S")
            date_end = date_end + " 23:59:59"
            date_end = Time.strptime(date_end, "%Y/%m/%d %H:%M:%S")

            # get all messages from the channel
            hist = []

            begin
              members = get_channel_members(channel)
            rescue
              members = []
            end
            if !members.include?(config.nick_id_granular) or !members.include?(config.nick_id) #monitor-smartbot #smartbot
              respond "Sorry, `recap` command requires <@#{config.nick_id_granular}> and <@#{config.nick_id}> to be in the channel. Please add them and try again."
            elsif !members.include?(user.id)
              respond "Sorry, `recap` command requires you to be in the channel. Please join the channel and try again."
            else

              client_granular.conversations_history(channel: channel, limit: 200, oldest: date_start.to_f, latest: date_end.to_f) do |response|
                hist << response.messages
              end
              hist_replies = hist.deep_copy()
              hist.flatten!

              # sort hist by reply_count from highest to lowest, reply_count is not always, return a hash
              hist.each do |message|
                if !message.key?("reply_count")
                  message[:reply_count] = 0
                end
              end
              num_posts = hist.length
              num_threads = hist.select { |msg| msg.key?("thread_ts") }.length

              hist_replies_count = hist.sort_by { |k| k[:reply_count] }
              # get the top 3 threads
              top_three_threads = []
              #hist_replies_count is not always 3, so we need to check if the index exists
              top_three_threads << hist_replies_count[-1] if hist_replies_count[-1] and hist_replies_count[-1].key?("thread_ts")
              top_three_threads << hist_replies_count[-2] if hist_replies_count[-2] and hist_replies_count[-2].key?("thread_ts")
              top_three_threads << hist_replies_count[-3] if hist_replies_count[-3] and hist_replies_count[-3].key?("thread_ts")

              num_messages_skipped = 0
              num_messages_not_skipped = 0
              hist.each do |message|
                if Time.at(message[:ts].to_f) >= date_start and Time.at(message[:ts].to_f) <= date_end
                  if message.key?("thread_ts")
                    if message.reply_users_count == 1 and message.reply_users[0] == config.nick_id
                      #if the thread has only one replier and it is from smartbot, then we don't need to get the replies from the thread
                      num_messages_skipped += 1
                      message[:reply_count].times do
                        hist_replies << { user: config.nick_id, ts: message.thread_ts, text: "" }
                      end
                    else
                      num_messages_not_skipped += 1
                      thread_ts = message.thread_ts
                      passed = false
                      num_tries = 0
                      while !passed and num_tries < 30
                        begin
                          num_tries += 1
                          replies = client_granular.conversations_replies(channel: channel, ts: thread_ts)
                          passed = true
                        rescue => e
                          @logger.info "recap command: threads num_tries: #{num_tries}"
                          @logger.fatal "recap command: threads error: #{e.message}"
                          sleep 1
                          passed = false
                        end
                      end
                      if !passed
                        respond "Sorry, `recap` command failed. <@#{config.admins.join(">,<@")}> please check the logs."
                        @history_still_running = false
                        unreact :runner
                        return
                      end
                      hist_replies << replies.messages
                      sleep 0.5 #to avoid rate limit Tier 3 (50 requests per minute)
                    end
                  end
                end
              end
              hist_replies.flatten!

              hist_user = {}
              hist_replies.each do |msg|
                hist_user[msg.user] ||= 0
                hist_user[msg.user] += 1
              end
              #sort hist_user by value from highest to lowest, return a hash
              hist_user = hist_user.sort_by { |k, v| v }.reverse.to_h
              #top_three_users excluding smartbot
              hist_user_wo_smartbot = hist_user.reject { |k, v| k == config.nick_id }

              top_three_users = hist_user_wo_smartbot.first(3).to_h
              messages << "\t :bar_chart: Totals:"
              messages << "\t\t\t messages: *#{hist_replies.length}*"
              messages << "\t\t\t SmartBot messages: *#{hist_user[config.nick_id]}* (#{hist_user[config.nick_id] * 100 / hist_replies.length} %)" if hist_user.key?(config.nick_id)
              messages << "\t\t\t posts: *#{num_posts}*"
              messages << "\t\t\t threads: *#{num_threads}*"

              num_replies = hist_replies.length - num_posts
              messages << "\t\t\t replies: *#{num_replies}*"

              messages << "\t\t\t users: *#{hist_user.length}*"
              if top_three_users.length > 0
                messages << "\n\t :boom: Top 3 users:"
                top_three_users.each do |user, num|
                  messages << "\t\t\t<@#{user}>: *#{num}*"
                end
              end

              #top 3 users posting excluding smartbot
              hist_user_posts = {}
              hist.each do |msg|
                hist_user_posts[msg.user] ||= 0
                hist_user_posts[msg.user] += 1
              end
              hist_user_posts = hist_user_posts.reject { |k, v| k == config.nick_id }
              hist_user_posts = hist_user_posts.sort_by { |k, v| v }.reverse.to_h
              top_three_users_posts = hist_user_posts.first(3).to_h
              if top_three_users_posts.length > 0
                messages << "\n\t :bust_in_silhouette: Top 3 users posting:"
                top_three_users_posts.each do |user, num|
                  messages << "\t\t\t<@#{user}>: *#{num}*"
                end
              end

              if top_three_threads.length > 0
                messages << "\n\t :star: Top 3 threads:"
                top_three_threads.each do |thread|
                  messages << "\t\t\t<@#{thread.user}>: *#{thread.reply_count}* replies. *<https://greenqloud.slack.com/archives/#{channel}/p#{thread.ts.gsub(".", "")}|#{thread.text[0..50].gsub(/[^a-zA-Z0-9\s]/, "").gsub("\n", "").strip}>*"
                end
              end

              #get the stats from the files, they are like smart-bot.stats.2020-01.log, smart-bot.stats.2020-02.log, etc.
              smartbot_stats = []
              Dir["#{config.stats_path}.*.log"].sort.each do |file|
                #read only the files that are in the range of date_start and date_end
                if file.match(/#{config.stats_path}\.(\d\d\d\d-\d\d)\.log/)
                  if $1 >= date_start.strftime("%Y-%m") and $1 <= date_end.strftime("%Y-%m")
                    smartbot_stats_file = CSV.read(file, headers: true, converters: :numeric)
                    #convert smartbot_stats_file to array of hashes
                    smartbot_stats_file = smartbot_stats_file.map(&:to_hash)
                    smartbot_stats << smartbot_stats_file
                  end
                end
              end
              smartbot_stats.flatten!

              #filter by bot_channel_id==channel and dest_channel_id!=channel and type_message==on_dm
              smartbot_stats_on_dm = smartbot_stats.deep_copy
              smartbot_stats_on_dm = smartbot_stats_on_dm.select { |msg| msg["bot_channel_id"] == channel and msg["dest_channel_id"] != channel and msg["type_message"] == "on_dm" }
              #filter by date_start and date_end. We store the date on "date" field like this: 2020-01-14 16:34:16
              smartbot_stats_on_dm = smartbot_stats_on_dm.select { |msg| Date.parse(msg["date"]) >= Date.parse(date_start.strftime("%Y-%m-%d")) and Date.parse(msg["date"]) <= Date.parse(date_end.strftime("%Y-%m-%d")) }

              #filter by bot_channel_id==channel and dest_channel_id!=channel and type_message!=on_dm
              smartbot_stats_external = smartbot_stats.deep_copy
              smartbot_stats_external = smartbot_stats_external.select { |msg| msg["bot_channel_id"] == channel and msg["dest_channel_id"] != channel and msg["type_message"] != "on_dm" }
              #filter by date_start and date_end. We store the date on "date" field like this: 2020-01-14 16:34:16
              smartbot_stats_external = smartbot_stats_external.select { |msg| Date.parse(msg["date"]) >= Date.parse(date_start.strftime("%Y-%m-%d")) and Date.parse(msg["date"]) <= Date.parse(date_end.strftime("%Y-%m-%d")) }

              # filter by dest_channel_id
              smartbot_stats = smartbot_stats.select { |msg| msg["dest_channel_id"] == channel }
              # filter by date_start and date_end. We store the date on "date" field like this: 2020-01-14 16:34:16
              smartbot_stats = smartbot_stats.select { |msg| Date.parse(msg["date"]) >= Date.parse(date_start.strftime("%Y-%m-%d")) and Date.parse(msg["date"]) <= Date.parse(date_end.strftime("%Y-%m-%d")) }

              #get the number of times SmartBot was called by a user, if field 'user_name' is not including 'routine/'
              smartbot_stats_user = {}
              smartbot_stats.each do |msg|
                if !msg["user_name"].include?("routine/")
                  smartbot_stats_user[msg["user_name"]] ||= 0
                  smartbot_stats_user[msg["user_name"]] += 1
                end
              end

              smartbot_stats_total = smartbot_stats_user.values.sum
              if smartbot_stats_total > 0
                messages << "\t :robot_face: *SmartBot* Stats:"
                #total of times SmartBot was called
                messages << "\t\t\t called by a user: *#{smartbot_stats_total}*"
                #total of times SmartBot was called by any user including routines
                smartbot_stats_total_all = smartbot_stats.length
                messages << "\t\t\t called on this channel: *#{smartbot_stats_total_all}*" if smartbot_stats_total != smartbot_stats_total_all
                #total of times SmartBot was called using this channel on a DM
                messages << "\t\t\t called on a DM using this channel: *#{smartbot_stats_on_dm.length}*" if smartbot_stats_on_dm.length > 0
                #total of times SmartBot was called using this channel from another channel
                messages << "\t\t\t called from another channel using this channel: *#{smartbot_stats_external.length}*" if smartbot_stats_external.length > 0

                #total of times SmartBot was used
                total_sb_calls = smartbot_stats_total_all + smartbot_stats_on_dm.length + smartbot_stats_external.length
                messages << "\t\t\t Total times SmartBot was used: *#{total_sb_calls}*" if total_sb_calls != smartbot_stats_total_all

                #get the three most used commands. The command is stored on "command" field
                smartbot_stats_commands = {}
                smartbot_stats.each do |msg|
                  smartbot_stats_commands[msg["command"]] ||= 0
                  smartbot_stats_commands[msg["command"]] += 1
                end

                #total number of different commands
                smartbot_stats_total_commands = smartbot_stats_commands.keys.length
                messages << "\t\t\t Total different commands used: *#{smartbot_stats_total_commands}*"

                #top three commands
                smartbot_stats_commands = smartbot_stats_commands.sort_by { |k, v| v }.reverse.to_h
                smartbot_stats_commands = smartbot_stats_commands.first(3).to_h
                messages << "\t\t\t :speech_balloon: Top 3 commands:"
                smartbot_stats_commands.each do |command, num|
                  messages << "\t\t\t\t*#{command}*: *#{num}*"
                end

                #top three commands excluding routines only if the top 3 is different from including routines
                smartbot_stats_commands_include_routines = smartbot_stats_commands.deep_copy

                smartbot_stats_commands = {}
                smartbot_stats.each do |msg|
                  if !msg["user_name"].include?("routine/")
                    smartbot_stats_commands[msg["command"]] ||= 0
                    smartbot_stats_commands[msg["command"]] += 1
                  end
                end
                smartbot_stats_commands = smartbot_stats_commands.sort_by { |k, v| v }.reverse.to_h
                smartbot_stats_commands = smartbot_stats_commands.first(3).to_h
                if smartbot_stats_commands != smartbot_stats_commands_include_routines
                  messages << "\t\t\t :speech_balloon: Top 3 commands excluding routines:"
                  smartbot_stats_commands.each do |command, num|
                    messages << "\t\t\t\t*#{command}*: *#{num}*"
                  end
                end

                #get the three most used users. The user is stored on "user_name" field
                smartbot_stats_user = smartbot_stats_user.sort_by { |k, v| v }.reverse.to_h
                smartbot_stats_user = smartbot_stats_user.first(3).to_h
                messages << "\t\t\t :bust_in_silhouette: Top 3 users calling SmartBot:"
                smartbot_stats_user.each do |user, num|
                  messages << "\t\t\t\t<@#{user}>: *#{num}*"
                end
              end

              #number of messages by month
              hist_month = {}
              hist_replies.each do |msg|
                if Time.at(msg[:ts].to_f) >= date_start and Time.at(msg[:ts].to_f) <= date_end
                  date = Time.at(msg[:ts].to_f).strftime("%Y/%m")
                  hist_month[date] ||= 0
                  hist_month[date] += 1
                end
              end
              hist_month = hist_month.sort_by { |k, v| k }.to_h
              respond messages.join("\n")
              messages = []
              messages << "\t :memo: Number of messages by month:" if hist_month.size > 0
              hist_month.each do |date, num|
                graph = ":large_yellow_square: " * (num.to_f * (10 * hist_month.size) / hist_replies.size).round(2)
                messages << "\t\t\t#{date}: #{graph} #{num} (#{num * 100 / hist_replies.size}%)"
              end

              #number of users by month
              hist_month_user = {}
              hist_replies.each do |msg|
                if Time.at(msg[:ts].to_f) >= date_start and Time.at(msg[:ts].to_f) <= date_end
                  date = Time.at(msg[:ts].to_f).strftime("%Y/%m")
                  hist_month_user[date] ||= []
                  hist_month_user[date] << msg.user
                end
              end
              hist_month_user = hist_month_user.sort_by { |k, v| k }.to_h
              respond messages.join("\n")
              messages = []
              messages << "\t :person_with_crown: Number of users by month:" if hist_month_user.size > 0
              total_users_by_month = 0
              hist_month_user.each do |date, users|
                total_users_by_month += users.uniq.length
              end
              hist_month_user.each do |date, users|
                graph = ":large_orange_square: " * (users.uniq.length.to_f * (10 * hist_month_user.size) / total_users_by_month).round(2)
                messages << "\t\t\t#{date}: #{graph} #{users.uniq.length} "
              end
              if my_recap
                respond messages.join("\n")
                messages = []
                messages << "\t :medal: *Recap for <@#{user[:id]}>*:"
                messages << "\t\t\tTotal messages: *#{hist_user[user[:id]]}*"
                # top three posts of user.name
                hist_user_posts = hist.select { |msg| msg.user == user[:id] }
                hist_user_posts = hist_user_posts.sort_by { |k| k[:reply_count] }
                top_three_posts = [hist_user_posts[-1], hist_user_posts[-2], hist_user_posts[-3]]
                messages << "\t\t\tTop 3 threads:"
                top_three_posts.each do |post|
                  if !post.nil?
                    messages << "\t\t\t\t *#{post.reply_count}* replies: *<https://greenqloud.slack.com/archives/#{channel}/p#{post.ts.gsub(".", "")}|#{post.text[0..50].gsub(/[^a-zA-Z0-9\s]/, "").gsub("\n", "").strip}>*"
                  end
                end

                #Add also stats from SmartBot commands for this user
                #filter stats by user
                smartbot_stats_user = smartbot_stats.select { |msg| msg["user_id"] == user[:id] }
                #get the number of times SmartBot was called by this user
                smartbot_stats_user_total = smartbot_stats_user.length
                messages << "\t\t\t SmartBot calls: *#{smartbot_stats_user_total}*"
                #get the three most used commands by this user
                smartbot_stats_user_commands = {}
                smartbot_stats_user.each do |msg|
                  smartbot_stats_user_commands[msg["command"]] ||= 0
                  smartbot_stats_user_commands[msg["command"]] += 1
                end
                if smartbot_stats_user_total > 0
                  #total number of different commands
                  smartbot_stats_user_total_commands = smartbot_stats_user_commands.keys.length
                  messages << "\t\t\t Different commands: *#{smartbot_stats_user_total_commands}*"
                  #top three commands
                  smartbot_stats_user_commands = smartbot_stats_user_commands.sort_by { |k, v| v }.reverse.to_h
                  smartbot_stats_user_commands = smartbot_stats_user_commands.first(3).to_h
                  messages << "\t\t\t :speech_balloon: Top 3 commands:"
                  smartbot_stats_user_commands.each do |command, num|
                    messages << "\t\t\t\t\t*#{command}*: *#{num}*"
                  end
                end
              end

              respond messages.join("\n")
            end
          end
        end
      rescue => e
        @logger.fatal "recap command failed: #{e.message}"
        @logger.fatal e.backtrace.inspect
        respond "Sorry, `recap` command failed. <@#{config.admins.join(">,<@")}> please check the logs."
      end
      @history_still_running = false
    end
    unreact :runner
  end
end
