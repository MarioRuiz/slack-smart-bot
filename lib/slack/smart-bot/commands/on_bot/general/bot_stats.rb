class SlackSmartBot
  # help: ----------------------------------------------
  # help: `bot stats`
  # helpmaster: `bot stats USER_NAME`
  # help: `bot stats exclude masters`
  # help: `bot stats exclude routines`
  # help: `bot stats from YYYY/MM/DD`
  # help: `bot stats from YYYY/MM/DD to YYYY/MM/DD`
  # help: `bot stats CHANNEL`
  # help: `bot stats CHANNEL from YYYY/MM/DD`
  # help: `bot stats CHANNEL from YYYY/MM/DD to YYYY/MM/DD`
  # help: `bot stats command COMMAND`
  # helpmaster: `bot stats USER_NAME from YYYY/MM/DD to YYYY/MM/DD`
  # helpmaster: `bot stats CHANNEL USER_NAME from YYYY/MM/DD to YYYY/MM/DD`
  # help: `bot stats CHANNEL exclude masters from YYYY/MM/DD to YYYY/MM/DD`
  # help: `bot stats HEADER /REGEXP/`
  # help: `bot stats members #CHANNEL`
  # help: `bot stats exclude members #CHANNEL`
  # help: `bot stats today`
  # help: `bot stats yesterday`
  # help: `bot stats last month`
  # help: `bot stats this month`
  # help: `bot stats last week`
  # help: `bot stats this week`
  # help: `bot stats exclude COMMAND_ID`
  # help: `bot stats monthly`
  # help: `bot stats alldata`
  # help: `bot stats weekly graph`
  # help:    To see the bot stats
  # helpmaster:    You can use this command only if you are a Master admin user and if you are in a private conversation with the bot, or you are on the Smartbot-stats channel
  # helpmaster:    You need to set stats to true to generate the stats when running the bot instance.
  # help:    members #CHANNEL will return stats for only members of the channel supplied
  # help:    exclude members #CHANNEL will return stats for only members that are not members of the channel supplied
  # help:    HEADER /REGEXP/ will return stats for only the rows that match the regexp on the stats header supplied
  # help:    If 'alldata' option supplied then it will be attached files including all data and not only the top 10.
  # help:    If 'graph' option supplied then it will be displaying only a graph.
  # help:    Examples:
  # help:      _bot stats #sales_
  # helpmaster:      _bot stats @peter.wind_
  # help:      _bot stats #sales from 2019/12/15 to 2019/12/31_
  # help:      _bot stats #sales today_
  # help:      _bot stats #sales from 2020-01-01 monthly_
  # help:      _bot stats exclude routines masters from 2021/01/01 monthly_
  # help:      _bot stats members #development from 2022/01/01 to 2022/01/31_
  # help:      _bot stats type_message /(on_pub|on_pg)/_
  # help:    <https://github.com/MarioRuiz/slack-smart-bot#bot-management|more info>
  # help: command_id: :bot_stats
  # help:
  def bot_stats(dest, from_user, typem, channel_id, from, to, user, st_command, exclude_masters, exclude_routines, exclude_command, monthly, all_data, members_channel, exclude_members_channel, header, regexp, type_group: '', only_graph: false)
    require "csv"
    if config.stats
      message = []
    else
      message = ["You need to set stats to true to generate the stats when running the bot instance."]
    end
    save_stats(__method__)
    react :runner
    get_channels_name_and_id() unless @channels_name.keys.include?(dest) or dest[0] == "D"
    master_admin_users_id = @master_admin_users_id.dup
    if dest == @channels_id[config.stats_channel]
      #master_admin_users_id << user
      user = "" # for the case we are on the stats channel
    end
    if (from_user.id != user and
        (config.team_id_masters.include?("#{from_user.team_id}_#{from_user.name}") or master_admin_users_id.include?(from_user.id) or dest == @channels_id[config.stats_channel]) and
        (typem == :on_dm or dest[0] == "D" or dest == @channels_id[config.stats_channel]))
      on_dm_master = true #master admin user
    else
      on_dm_master = false
    end
    wrong = false
    exclude_channel_members = false
    include_channel_members = false
    members_list = []
    if exclude_members_channel != "" or members_channel != ""
      if members_channel != ""
        channel_members = members_channel
        include_channel_members = true
      else
        channel_members = exclude_members_channel
        exclude_channel_members = true
      end
      get_channels_name_and_id() unless @channels_id.keys.include?(channel_members)

      tm = get_channel_members(channel_members)
      if tm.nil? or tm.size == 0
        message << ":exclamation: Add the Smart Bot to *<##{channel_members}>* channel first."
        wrong = true
      else
        tm.each do |m|
          user_info = find_user(m)
          members_list << user_info.name unless user_info.is_app_user or user_info.is_bot
        end
      end
    end
    if header.size > 0
      headers = ["date", "bot_channel", "bot_channel_id", "dest_channel", "dest_channel_id", "type_message", "user_name", "user_id", "text", "command", "files", "time_zone", "job_title", "team_id"]
      header.each do |h|
        if !headers.include?(h.downcase)
          message << ":exclamation: Wrong header #{h}. It should be one of the following: #{headers.join(", ")}"
          wrong = true
        end
      end
      if regexp.size > 0
        regexp.each do |r|
          begin
            Regexp.new(r)
          rescue
            message << ":exclamation: Wrong regexp #{r}."
            wrong = true
          end
        end
      end
    end

    tzone_users = {}
    job_title_users = {}
    users_by_job_title = {}
    users_by_team = {}
    total_calls_by_team = {}
    unless wrong
      type_group = :monthly if only_graph and type_group == ""
      if on_dm_master or (from_user.id == user) # normal user can only see own stats
        if !File.exist?("#{config.stats_path}.#{Time.now.strftime("%Y-%m")}.log")
          message << "No stats"
        else
          from = "#{Time.now.strftime("%Y-%m")}-01" if from == ""
          to = "#{Time.now.strftime("%Y-%m-%d")}" if to == ""
          from_short = from
          to_short = to
          days = Date.parse(to_short) - Date.parse(from_short)
          weeks = days/7
          if type_group == :daily and days > 60
            message << ":exclamation: You can only see daily stats for a maximum of 60 days."
            wrong = true
          elsif type_group == :weekly and weeks > 60
            message << ":exclamation: You can only see weekly stats for a maximum of 60 weeks."
            wrong = true
          end
          unless wrong
            from_file = from[0..3] + "-" + from[5..6]
            to_file = to[0..3] + "-" + to[5..6]
            from += " 00:00:00 +0000"
            to += " 23:59:59 +0000"
            rows = []
            rows_group = {}
            users_group = {}
            commands_group = {}
            users_id_name = {}
            users_name_id = {}
            count_users = {}
            count_channels_dest = {}
            # to translate global and enterprise users since sometimes was returning different names/ids
            #if from[0..3]=='2020' # this was an issue only on that period
            Dir["#{config.stats_path}.*.log"].sort.each do |file|
              if file >= "#{config.stats_path}.#{from_file}.log" and file <= "#{config.stats_path}.#{to_file}.log"
                CSV.foreach(file, headers: true, header_converters: :symbol, converters: :numeric) do |row|
                  unless users_id_name.key?(row[:user_id])
                    users_id_name[row[:user_id]] = row[:user_name]
                    users_name_id[row[:user_name]] = row[:user_id]
                  end
                end
              end
            end
            #end
            if user != ""
              user_info = find_user(user)
              if user_info.nil? # for the case the user is populated from outside of slack
                user_name = user
                user_id = user
              else
                if users_id_name.key?(user_info.id)
                  user_name = users_id_name[user_info.id]
                else
                  user_name = user_info.name
                end
                if users_name_id.key?(user_info.name)
                  user_id = users_name_id[user_info.name]
                else
                  user_id = user_info.id
                end
              end
            end
            master_admins = config.masters.dup
            if users_id_name.size > 0
              config.masters.each do |u|
                if users_id_name.key?(u)
                  master_admins << users_id_name[u]
                elsif users_name_id.key?(u)
                  master_admins << users_name_id[u]
                end
              end
            end
            Dir["#{config.stats_path}.*.log"].sort.each do |file|
              if file >= "#{config.stats_path}.#{from_file}.log" and file <= "#{config.stats_path}.#{to_file}.log"
                CSV.foreach(file, headers: true, header_converters: :symbol, converters: :numeric) do |row|
                  clean_user_name = row[:user_name].gsub('routine/','')
                  if (include_channel_members and members_list.include?(clean_user_name)) or
                    (exclude_channel_members and !members_list.include?(clean_user_name)) or
                    (!include_channel_members and !exclude_channel_members)
                    row[:date] = row[:date].to_s
                    row[:team_id] = config.team_id if row[:team_id].to_s == ''
                    if row[:dest_channel_id].to_s[0] == "D"
                      row[:dest_channel] = "DM"
                    elsif row[:dest_channel].to_s == ""
                      row[:dest_channel] = row[:dest_channel_id]
                    end
                    if users_name_id.size > 0
                      row[:user_name] = users_id_name[row[:user_id]]
                      row[:user_id] = users_name_id[row[:user_name]]
                    else
                      users_id_name[row[:user_id]] ||= row[:user_name]
                    end
                    if !exclude_masters or (exclude_masters and !master_admins.include?(row[:user_name]) and
                                            !master_admins.include?(row[:user_id]) and
                                            !master_admin_users_id.include?(row[:user_id]))
                      if !exclude_routines or (exclude_routines and !row[:user_name].match?(/^routine\//))
                        unless header.empty?
                          add = true
                          header.each_with_index do |h, i|
                            if !row[h.downcase.to_sym].to_s.match?(/#{regexp[i]}/i)
                              add = false
                              break
                            end
                          end
                        end
                        if header.empty? or (header.size > 0 and add)
                          if exclude_command == "" or (exclude_command != "" and row[:command] != exclude_command)
                            if st_command == "" or (st_command != "" and row[:command] == st_command)
                              if row[:bot_channel_id] == channel_id or channel_id == "" or row[:dest_channel_id] == channel_id
                                if row[:date] >= from and row[:date] <= to
                                  count_users[row[:user_id]] ||= 0
                                  count_users[row[:user_id]] += 1
                                  if user == "" or (user != "" and row[:user_name] == user_name) or (user != "" and row[:user_id] == user_id)
                                    rows << row.to_h
                                    count_channels_dest[row[:dest_channel]] ||= 0
                                    count_channels_dest[row[:dest_channel]] += 1
                                    if type_group != ''#Ja
                                    case type_group
                                      when :monthly
                                        group_range = row[:date][0..6]
                                      when :weekly
                                        group_range = Date.parse(row[:date]).strftime('%Y-%V')
                                      when :daily
                                        group_range = row[:date][0..9]
                                      when :yearly
                                        group_range = row[:date][0..3]
                                      end
                                      rows_group[group_range] = 0 unless rows_group.key?(group_range)
                                      users_group[group_range] = [] unless users_group.key?(group_range)
                                      commands_group[group_range] = [] unless commands_group.key?(group_range)
                                      rows_group[group_range] += 1
                                      users_group[group_range] << row[:user_id]
                                      commands_group[group_range] << row[:command]
                                    end
                                  end
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
            total = rows.size
            if exclude_masters
              message << "Excluding master admins"
            end
            if exclude_routines
              message << "Excluding routines"
            end
            if exclude_command != ""
              message << "Excluding command #{exclude_command}"
            end
            if st_command != ""
              message << "Including only command #{st_command}"
            end
            if include_channel_members
              message << "Including only members of <##{members_channel}>"
            end
            if exclude_channel_members
              message << "Including only members that are not members of <##{exclude_members_channel}>"
            end
            if header.size > 0
              header.each_with_index do |h, i|
                message << "Including only #{h} that match /#{regexp[i]}/i"
              end
            end
            if user != ""
              if user == from_user.id
                message << "Bot stats for <@#{user}>"
              else
                message << "Showing only user <@#{user}>"
              end
            end
            if channel_id == ""
              message << "*Total calls*: #{total} from #{from_short} to #{to_short}"
            else
              message << "*Total calls <##{channel_id}>*: #{total} from #{from_short} to #{to_short}"
            end
            unless count_users.size == 0 or total == 0 or user == ""
              my_place = (count_users.sort_by(&:last).reverse.to_h.keys.index(user_id) + 1)
              message << "\tYou are the *\# #{my_place}* of *#{count_users.size}* users"
            end
            if total > 0
              if type_group != ''
                if on_dm_master
                  message << "*Totals #{type_group} / commands / users (%new)*"
                else
                  message << "*Totals #{type_group} / commands*"
                end

                all_users = []
                new_users = []
                rows_group.each do |k, v|
                  if all_users.empty?
                    message_new_users = ""
                  else
                    new_users = (users_group[k] - all_users).uniq
                    message_new_users = "(#{new_users.size * 100 / users_group[k].uniq.size}%)"
                  end
                  all_users += users_group[k]
                  graph = ":large_yellow_square: " * (v.to_f * (10*rows_group.size) / total).round(2)
                  if on_dm_master
                    message << "\t#{k}: #{graph} #{v} (#{(v.to_f * 100 / total).round(2)}%) / #{commands_group[k].uniq.size} / #{users_group[k].uniq.size} #{message_new_users}"
                  else
                    message << "\t#{k}: #{graph} #{v} (#{(v.to_f * 100 / total).round(2)}%) / #{commands_group[k].uniq.size}"
                  end
                end
              end

              if channel_id == ""
                message << "*SmartBots*"
                channels = rows.bot_channel.uniq.sort
                channels.each do |channel|
                  count = rows.count { |h| h.bot_channel == channel }
                  channel_info = @channels_list.select { |c| c.name.to_s.downcase == channel.to_s.downcase }[-1]
                  if @channels_id.key?(channel) and !channel_info.is_private
                    c = "<##{@channels_id[channel]}>"
                  else
                    c = channel
                  end
                  message << "\t#{c}: #{count} (#{(count.to_f * 100 / total).round(2)}%)"
                end
              end
              channels_dest_attachment = []
              count_channels_dest = count_channels_dest.sort_by(&:last).reverse.to_h
              if count_channels_dest.size > 10
                message << "*From Channel* - #{count_channels_dest.size} (Top 10)"
              else
                message << "*From Channel* - #{count_channels_dest.size}"
              end

              count_channels_dest.keys[0..9].each do |ch|
                channel_info = @channels_list.select { |c| c.name.to_s.downcase == ch.to_s.downcase }[-1]
                if @channels_id.key?(ch) and !channel_info.is_private
                  c = "<##{@channels_id[ch]}>"
                else
                  c = ch
                end
                message << "\t#{c}: #{count_channels_dest[ch]} (#{(count_channels_dest[ch].to_f * 100 / total).round(2)}%)"
              end
              if count_channels_dest.size > 10 and all_data
                count_channels_dest.each do |ch, value|
                  channel_info = @channels_list.select { |c| c.name.to_s.downcase == ch.to_s.downcase }[-1]
                  channels_dest_attachment << "\t##{ch}: #{value} (#{(value.to_f * 100 / total).round(2)}%)"
                end
              end

              team_ids = rows.team_id.uniq
              client_web = Slack::Web::Client.new(token: config.token)
              client_web.auth_test
              team_ids.each do |team_id|
                resp = client_web.team_info(team: team_id)
                team_name = resp.team.name
                users_by_team[team_name] ||= []
                users_by_team[team_name] += rows.select { |h| h.team_id == team_id }.map { |h| h.user_id }.uniq
                total_calls_by_team[team_name] ||= 0
                total_calls_by_team[team_name] += rows.count { |h| h.team_id == team_id }
              end
              client_web = nil

              #print users by team
              if users_by_team.size > 0
                total_users = rows.user_id.uniq.size
                message << "*Users by Space*"
                users_by_team.each do |team_name, users|
                  message << "\t#{team_name}: #{users.size} (#{(users.size.to_f * 100 / total_users).round(2)}%)"
                end
              end

              #print total calls by user team
              if total_calls_by_team.size > 0
                message << "*Total calls by User Space*"
                total_calls_by_team.each do |team_name, total_calls|
                  message << "\t#{team_name}: #{total_calls} (#{(total_calls.to_f * 100 / total).round(2)}%)"
                end
              end

              if !only_graph
                users_attachment = []
                if user == ""
                  users = rows.user_id.uniq.sort
                  if rows[0].key?(:time_zone) #then save_stats is saving the time zone already
                    rows.time_zone.each_with_index do |time_zone, idx|
                      unless time_zone == "" or rows.user_name[idx].match?(/^routine\//)
                        tzone_users[time_zone] ||= 0
                        tzone_users[time_zone] += 1
                      end
                    end
                  else
                    rows.user_id.each_with_index do |usr, i|
                      if rows[i].values.size >= 12 #then save_stats is saving the time zone already but not all the data
                        unless rows[i].values[11] == "" or rows[i].values[11].match?(/^routine\//)
                          tzone_users[rows[i].values[11]] ||= 0
                          tzone_users[rows[i].values[11]] += 1
                        end
                      else
                        user_info = find_user(usr)
                        unless user_info.nil? or user_info.is_app_user or user_info.is_bot or user_info.tz_label.to_s == "" or rows.user_name[i].match?(/^routine\//)
                          tzone_users[user_info.tz_label] ||= 0
                          tzone_users[user_info.tz_label] += 1
                        end
                      end
                    end
                  end
                  if rows[0].key?(:job_title) #then save_stats is saving the job title already
                    rows.job_title.each_with_index do |job_title, idx|
                      unless job_title.to_s == "" or rows.user_name[idx].match?(/^routine\//)
                        unless job_title_users.key?(job_title)
                          job_title = job_title.to_s.split.map { |x| x[0].upcase + x[1..-1] }.join(" ")
                          job_title_users[job_title] ||= 0
                          users_by_job_title[job_title] ||= []
                        end
                        job_title_users[job_title] += 1
                        users_by_job_title[job_title] << rows.user_name[idx]
                      end
                    end
                  else
                    rows.user_id.each_with_index do |usr, i|
                      unless usr.include?("routine/")
                        if rows[i].values.size >= 13 #then save_stats is saving the job_title already but not all the data
                          unless rows[i].values[12].to_s == ""
                            if job_title_users.key?(rows[i].values[12].to_s)
                              job_title = rows[i].values[12]
                            else
                              job_title = rows[i].values[12].to_s.split.map { |x| x[0].upcase + x[1..-1] }.join(" ")
                              job_title_users[job_title] ||= 0
                              users_by_job_title[job_title] ||= []
                            end
                            job_title_users[job_title] += 1
                            users_by_job_title[job_title] << rows.user_name[i]
                          end
                        else
                          user_info = find_user(usr)
                          unless user_info.nil? or user_info.is_app_user or user_info.is_bot
                            if job_title_users.key?(user_info.profile.title)
                              job_title = user_info.profile.title
                            else
                              job_title = user_info.profile.title.split.map { |x| x[0].upcase + x[1..-1] }.join(" ")
                            end
                            unless job_title.to_s == ""
                              job_title_users[job_title] ||= 0
                              job_title_users[job_title] += 1
                              users_by_job_title[job_title] ||= []
                              users_by_job_title[job_title] << rows.user_name[i]
                            end
                          end
                        end
                      end
                    end
                  end
                  users_by_job_title.each do |job_title, users|
                    users.uniq!
                  end

                  if users.size > 10
                    message << "*Users* - #{users.size} (Top 10)"
                  else
                    message << "*Users* - #{users.size}"
                  end
                  count_user = {}
                  users.each do |user|
                    count = rows.count { |h| h.user_id == user }
                    count_user[user] = count
                  end
                  i = 0
                  total_without_routines = total
                  count_user.sort_by { |k, v| -v }.each do |user, count|
                    i += 1
                    if user.include?("routine/")
                      user_link = users_id_name[user]
                      total_without_routines -= count
                    else
                      user_link = "<@#{user}>"
                    end
                    if i <= 10
                      message << "\t#{user_link}: #{count} (#{(count.to_f * 100 / total).round(2)}%)"
                    end
                    if users.size > 10 and all_data
                      users_attachment << "\t#{users_id_name[user]}: #{count} (#{(count.to_f * 100 / total).round(2)}%)"
                    end
                  end
                  if tzone_users.size > 0
                    message << "*Time Zones*"
                    total_known = 0
                    tzone_users.each do |tzone, num|
                      unless tzone.to_s == ""
                        abb_tzone = tzone.split.map{|i| i[0,1].upcase}.join
                        message << "\t#{abb_tzone} _#{tzone}_: #{num} (#{(num.to_f * 100 / total_without_routines).round(2)}%)"
                        total_known += num
                      end
                    end
                    total_unknown = total_without_routines - total_known
                    message << "\tUnknown: #{total_unknown} (#{(total_unknown.to_f * 100 / total_without_routines).round(2)}%)" if total_unknown > 0
                  end
                  if users.size > 0
                    if job_title_users.size > 10
                      message << "*Job Titles* - #{job_title_users.size} (Top 10)"
                    else
                      message << "*Job Titles* - #{job_title_users.size}"
                    end
                    total_known = 0
                    i = 0
                    job_title_users.sort_by { |k, v| -v }.each do |jtitle, num|
                      unless jtitle.to_s == ""
                        i += 1
                        if i <= 10
                          message << "\t#{jtitle}: #{num} (#{(num.to_f * 100 / total_without_routines).round(2)}%)"
                        end
                        total_known += num
                      end
                    end
                    total_unknown = total_without_routines - total_known
                    message << "\tUnknown: #{total_unknown} (#{(total_unknown.to_f * 100 / total_without_routines).round(2)}%)" if total_unknown > 0
                  end
                  if users.size > 0
                    if users_by_job_title.size > 10
                      message << "*Num Users by Job Title* (Top 10)"
                    else
                      message << "*Num Users by Job Title*"
                    end
                    i = 0
                    users_size_without_routines = users.delete_if { |u| u.include?("routine/") }.size
                    users_by_job_title.sort_by { |k, v| -v.size }.each do |jtitle, usersj|
                      i += 1
                      if i <= 10
                        message << "\t#{jtitle}: #{usersj.size} (#{(usersj.size.to_f * 100 / users_size_without_routines).round(2)}%)"
                      end
                    end
                  end
                end
                commands_attachment = []

                if st_command == ""
                  commands = rows.command.uniq.sort
                  count_command = {}
                  commands.each do |command|
                    count = rows.count { |h| h.command == command }
                    count_command[command] = count
                  end

                  if commands.size > 10
                    message << "*Commands* - #{commands.size} (Top 10)"
                  else
                    message << "*Commands* - #{commands.size}"
                  end

                  i = 0
                  count_command.sort_by { |k, v| -v }.each do |command, count|
                    i += 1
                    if i <= 10
                      message << "\t#{command}: #{count} (#{(count.to_f * 100 / total).round(2)}%)"
                    end
                    if commands.size > 10 and all_data
                      commands_attachment << "\t#{command}: #{count} (#{(count.to_f * 100 / total).round(2)}%)"
                    end
                  end
                end

                message << "*Message type*"
                types = rows.type_message.uniq.sort
                types.each do |type|
                  count = rows.count { |h| h.type_message == type }
                  message << "\t#{type}: #{count} (#{(count.to_f * 100 / total).round(2)}%)"
                end

                if on_dm_master
                  message << "*Last activity*: #{rows[-1].date} #{rows[-1].bot_channel} #{rows[-1].type_message} #{rows[-1].user_name} #{rows[-1].command}"
                end
                if users_attachment.size > 0
                  send_file(dest, "", "users.txt", "", "text/plain", "text", content: users_attachment.join("\n"))
                end
                if commands_attachment.size > 0
                  send_file(dest, "", "commands.txt", "", "text/plain", "text", content: commands_attachment.join("\n"))
                end
                if channels_dest_attachment.size > 0
                  send_file(dest, "", "channels_dest.txt", "", "text/plain", "text", content: channels_dest_attachment.join("\n"))
                end
              end
            end
          end
        end
      else
        message << "Only Master admin users on a private conversation with the bot can see this kind of bot stats."
      end
    end
    unreact :runner
    respond "#{message.join("\n")}", dest
  end
end
