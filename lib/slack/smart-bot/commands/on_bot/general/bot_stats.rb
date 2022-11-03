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
    # help: `bot stats members #CHANNEL`
    # help: `bot stats exclude members #CHANNEL`
    # help: `bot stats today`
    # help: `bot stats exclude COMMAND_ID`
    # help: `bot stats monthly`
    # help: `bot stats alldata`
    # help:    To see the bot stats
    # helpmaster:    You can use this command only if you are a Master admin user and if you are in a private conversation with the bot
    # helpmaster:    You need to set stats to true to generate the stats when running the bot instance.
    # help:    members #CHANNEL will return stats for only members of the channel supplied
    # help:    exclude members #CHANNEL will return stats for only members that are not members of the channel supplied
    # help:    If alldata option supplied then it will be attached files including all data and not only the top 10.
    # help:    Examples:
    # help:      _bot stats #sales_
    # helpmaster:      _bot stats @peter.wind_
    # help:      _bot stats #sales from 2019/12/15 to 2019/12/31_
    # help:      _bot stats #sales today_
    # help:      _bot stats #sales from 2020-01-01 monthly_
    # help:      _bot stats exclude routines masters from 2021/01/01 monthly_
    # help:      _bot stats members #development from 2022/01/01 to 2022/01/31_
    # help:    <https://github.com/MarioRuiz/slack-smart-bot#bot-management|more info>
    # help: command_id: :bot_stats
    # help:
    def bot_stats(dest, from_user, typem, channel_id, from, to, user, st_command, exclude_masters, exclude_routines, exclude_command, monthly, all_data, members_channel, exclude_members_channel)
        require 'csv'
        if config.stats
            message = []
        else
            message = ["You need to set stats to true to generate the stats when running the bot instance."]
        end
        save_stats(__method__)
        if (from_user.id != user and (config.masters.include?(from_user.name) or @master_admin_users_id.include?(from_user.id)) and (typem==:on_dm or dest[0]=='D'))
            on_dm_master = true #master admin user
        else
            on_dm_master = false
        end
        wrong = false
        exclude_channel_members = false
        include_channel_members = false
        members_list = []
        if exclude_members_channel!='' or members_channel!=''
            if members_channel!=''
                channel_members = members_channel
                include_channel_members = true
            else
                channel_members = exclude_members_channel
                exclude_channel_members = true                
            end
            get_channels_name_and_id() unless @channels_id.keys.include?(channel_members)

            tm = get_channel_members(channel_members)
            if tm.nil?
                message << ":exclamation: Add the Smart Bot to *<##{channel_members}>* channel first."
                wrong = true
            else
              tm.each do |m|
                user_info = @users.select { |u| u.id == m or (u.key?(:enterprise_user) and u.enterprise_user.id == m) }[-1]
                members_list << user_info.name unless user_info.is_app_user or user_info.is_bot
              end
            end
        end
        tzone_users = {}
        job_title_users = {}
        users_by_job_title = {}

        unless wrong
            if on_dm_master or (from_user.id == user) # normal user can only see own stats 
                if !File.exist?("#{config.stats_path}.#{Time.now.strftime("%Y-%m")}.log")
                    message<<'No stats'
                else
                    from = "#{Time.now.strftime("%Y-%m")}-01" if from == ''
                    to = "#{Time.now.strftime("%Y-%m-%d")}" if to == ''
                    from_short = from
                    to_short = to
                    from_file = from[0..3] + '-' + from[5..6]
                    to_file = to[0..3] + '-' + to[5..6]
                    from+= " 00:00:00 +0000"
                    to+= " 23:59:59 +0000"
                    rows = []
                    rows_month = {}
                    users_month = {}
                    commands_month = {}
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
        
                    if user!=''
                        user_info = @users.select{|u| u.id == user or (u.key?(:enterprise_user) and u.enterprise_user.id == user)}[-1]
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
                                if (include_channel_members and members_list.include?(row[:user_name])) or 
                                    (exclude_channel_members and !members_list.include?(row[:user_name])) or
                                    (!include_channel_members and !exclude_channel_members)

                                    row[:date] = row[:date].to_s
                                    if row[:dest_channel_id].to_s[0]=='D'
                                        row[:dest_channel] = 'DM'
                                    elsif row[:dest_channel].to_s == ''
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
                                                            !@master_admin_users_id.include?(row[:user_id]))
                                        if !exclude_routines or (exclude_routines and !row[:user_name].match?(/^routine\//) )
                                            if exclude_command == '' or (exclude_command!='' and row[:command]!=exclude_command)
                                                if st_command == '' or (st_command != '' and row[:command] == st_command)
                                                    if row[:bot_channel_id] == channel_id or channel_id == '' or row[:dest_channel_id] == channel_id
                                                        if row[:date] >= from and row[:date] <= to
                                                            count_users[row[:user_id]] ||= 0
                                                            count_users[row[:user_id]] += 1
                                                            if user=='' or (user!='' and row[:user_name] == user_name) or (user!='' and row[:user_id] == user_id)
                                                                rows << row.to_h
                                                                count_channels_dest[row[:dest_channel]] ||= 0
                                                                count_channels_dest[row[:dest_channel]] += 1
                                                                if monthly
                                                                    rows_month[row[:date][0..6]] = 0 unless rows_month.key?(row[:date][0..6])
                                                                    users_month[row[:date][0..6]] = [] unless users_month.key?(row[:date][0..6])
                                                                    commands_month[row[:date][0..6]] = [] unless commands_month.key?(row[:date][0..6])
                                                                    rows_month[row[:date][0..6]] += 1
                                                                    users_month[row[:date][0..6]] << row[:user_id]
                                                                    commands_month[row[:date][0..6]] << row[:command]
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
                        message << 'Excluding master admins'
                    end
                    if exclude_routines
                        message << 'Excluding routines'
                    end
                    if exclude_command != ''
                        message << "Excluding command #{exclude_command}"
                    end
                    if st_command != ''
                        message << "Including only command #{st_command}"
                    end
                    if include_channel_members
                        message << "Including only members of <##{members_channel}>"
                    end
                    if exclude_channel_members
                        message << "Including only members that are not members of <##{exclude_members_channel}>"
                    end
                    if user!=''
                        if user==from_user.id
                            message << "Bot stats for <@#{user}>"
                        else
                            message << "Showing only user <@#{user}>"
                        end
                    end
                    if channel_id == ''
                        message << "*Total calls*: #{total} from #{from_short} to #{to_short}"
                    else
                        message << "*Total calls <##{channel_id}>*: #{total} from #{from_short} to #{to_short}"
                    end
                    unless count_users.size == 0 or total == 0 or user == ''
                        my_place = (count_users.sort_by(&:last).reverse.to_h.keys.index(user_id)+1)
                        message <<"\tYou are the *\# #{my_place}* of *#{count_users.size}* users"
                    end
                    if total > 0
                        if monthly 
                            if on_dm_master
                                message << '*Totals by month / commands / users (%new)*'
                            else
                                message << '*Totals by month / commands*'
                            end

                            all_users = []
                            new_users = []
                            rows_month.each do |k,v|
                                if all_users.empty?
                                    message_new_users = ''
                                else
                                    new_users = (users_month[k]-all_users).uniq
                                    message_new_users = "(#{new_users.size*100/users_month[k].uniq.size}%)"
                                end
                                all_users += users_month[k]
                                if on_dm_master
                                    message << "\t#{k}: #{v} (#{(v.to_f*100/total).round(2)}%) / #{commands_month[k].uniq.size} / #{users_month[k].uniq.size} #{message_new_users}"
                                else
                                    message << "\t#{k}: #{v} (#{(v.to_f*100/total).round(2)}%) / #{commands_month[k].uniq.size}"
                                end
                            end
                        end
        
                        if channel_id == ''
                            message << "*SmartBots*"
                            channels = rows.bot_channel.uniq.sort
                            channels.each do |channel|
                                count = rows.count {|h| h.bot_channel==channel}
                                channel_info = @channels_list.select { |c| c.name.to_s.downcase == channel.to_s.downcase}[-1]
                                if @channels_id.key?(channel) and !channel_info.is_private
                                    c = "<##{@channels_id[channel]}>"
                                else
                                    c = channel
                                end
                                message << "\t#{c}: #{count} (#{(count.to_f*100/total).round(2)}%)"
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
                            channel_info = @channels_list.select { |c| c.name.to_s.downcase == ch.to_s.downcase}[-1]
                            if @channels_id.key?(ch) and !channel_info.is_private
                                c = "<##{@channels_id[ch]}>"
                            else
                                c = ch
                            end
                            message << "\t#{c}: #{count_channels_dest[ch]} (#{(count_channels_dest[ch].to_f*100/total).round(2)}%)"
                        end
                        if count_channels_dest.size > 10 and all_data
                            count_channels_dest.each do |ch, value|
                                channel_info = @channels_list.select { |c| c.name.to_s.downcase == ch.to_s.downcase}[-1]
                                channels_dest_attachment << "\t##{ch}: #{value} (#{(value.to_f*100/total).round(2)}%)"
                            end
                        end
                        
                        users_attachment = []
                        if user==''
                            users = rows.user_id.uniq.sort
                            if rows[0].key?(:time_zone) #then save_stats is saving the time zone already
                                rows.time_zone.each do |time_zone|
                                    unless time_zone == ''
                                        tzone_users[time_zone] ||= 0
                                        tzone_users[time_zone] += 1
                                    end
                                end
                            else
                                rows.user_id.each_with_index do |usr, i|
                                    if rows[i].values.size >= 12 #then save_stats is saving the time zone already but not all the data
                                        unless rows[i].values[11] == ''
                                            tzone_users[rows[i].values[11]] ||= 0
                                            tzone_users[rows[i].values[11]] += 1    
                                        end
                                    else
                                        user_info = @users.select { |u| u.id == usr or (u.key?(:enterprise_user) and u.enterprise_user.id == usr) }[-1]
                                        unless user_info.nil? or user_info.is_app_user or user_info.is_bot
                                            tzone_users[user_info.tz_label] ||= 0
                                            tzone_users[user_info.tz_label] += 1
                                        end
                                    end
                                end
                            end
                            if rows[0].key?(:job_title) #then save_stats is saving the job title already
                                rows.job_title.each_with_index do |job_title, idx|
                                    unless job_title == ''
                                        job_title_users[job_title] ||= 0
                                        job_title_users[job_title] += 1
                                        users_by_job_title[job_title] ||= []
                                        users_by_job_title[job_title] << rows.user_name[idx]
                                    end
                                end
                            else
                                rows.user_id.each_with_index do |usr, i|
                                    if rows[i].values.size >= 13 #then save_stats is saving the job_title already but not all the data
                                        unless rows[i].values[12] == ''
                                            job_title_users[rows[i].values[12]] ||= 0
                                            job_title_users[rows[i].values[12]] += 1    
                                            users_by_job_title[rows[i].values[12]] ||= []
                                            users_by_job_title[rows[i].values[12]] << rows.user_name[i]
                                        end
                                    else
                                        user_info = @users.select { |u| u.id == usr or (u.key?(:enterprise_user) and u.enterprise_user.id == usr) }[-1]
                                        unless user_info.nil? or user_info.is_app_user or user_info.is_bot
                                            job_title_users[user_info.profile.title] ||= 0
                                            job_title_users[user_info.profile.title] += 1
                                            users_by_job_title[user_info.profile.title] ||= []
                                            users_by_job_title[user_info.profile.title] << rows.user_name[i]
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
                                count = rows.count {|h| h.user_id==user}
                                count_user[user] = count
                            end
                            i = 0
                            total_without_routines = total
                            count_user.sort_by {|k,v| -v}.each do |user, count|
                                i+=1
                                if user.include?('routine/')
                                    user_link = users_id_name[user]
                                    total_without_routines -= count
                                else
                                    user_link = "<@#{user}>"
                                end
                                if i <= 10
                                    message << "\t#{user_link}: #{count} (#{(count.to_f*100/total).round(2)}%)"
                                end
                                if users.size > 10 and all_data
                                    users_attachment << "\t#{users_id_name[user]}: #{count} (#{(count.to_f*100/total).round(2)}%)"
                                end
                            end

                            if tzone_users.size > 0
                                message << "*Time Zones*"
                                total_known = 0
                                tzone_users.each do |tzone, num|
                                    unless tzone.to_s == ''
                                        message << "\t#{tzone}: #{num} (#{(num.to_f*100/total_without_routines).round(2)}%)"
                                        total_known+=num
                                    end
                                end
                                total_unknown = total_without_routines - total_known
                                message << "\tUnknown: #{total_unknown} (#{(total_unknown.to_f*100/total_without_routines).round(2)}%)" if total_unknown > 0
                            end
                            
                            if job_title_users.size > 0
                                if job_title_users.size > 10
                                    message << "*Job Titles* - #{job_title_users.size} (Top 10)"
                                else
                                    message << "*Job Titles* - #{job_title_users.size}"
                                end
                                total_known = 0
                                i = 0
                                job_title_users.sort_by {|k,v| -v}.each do |jtitle, num|
                                    unless jtitle.to_s == ''
                                        i += 1
                                        if i <= 10
                                            message << "\t#{jtitle}: #{num} (#{(num.to_f*100/total_without_routines).round(2)}%)"
                                        end
                                        total_known+=num
                                    end
                                end
                                total_unknown = total_without_routines - total_known
                                message << "\tUnknown: #{total_unknown} (#{(total_unknown.to_f*100/total_without_routines).round(2)}%)" if total_unknown > 0
                            end
                            if users_by_job_title.size > 0
                                if users_by_job_title.size > 10
                                    message << "*Num Users by Job Title* (Top 10)"
                                else
                                    message << "*Num Users by Job Title*"
                                end
                                i = 0
                                users_by_job_title.sort_by {|k,v| -v.size}.each do |jtitle, users|
                                    i += 1
                                    if i <= 10
                                        jtitle = 'Unknown' if jtitle.to_s == ''
                                        message << "\t#{jtitle}: #{users.size}"
                                    end
                                end
                            end
                        end
                        commands_attachment = []

                        if st_command == ''
                            commands = rows.command.uniq.sort
                            count_command = {}
                            commands.each do |command|
                                count = rows.count {|h| h.command==command}
                                count_command[command] = count
                            end

                            if commands.size > 10
                                message << "*Commands* - #{commands.size} (Top 10)"
                            else
                                message << "*Commands* - #{commands.size}"
                            end

                            i = 0
                            count_command.sort_by {|k,v| -v}.each do |command, count|
                                i+=1
                                if i <= 10
                                    message << "\t#{command}: #{count} (#{(count.to_f*100/total).round(2)}%)"
                                end
                                if commands.size > 10 and all_data
                                    commands_attachment << "\t#{command}: #{count} (#{(count.to_f*100/total).round(2)}%)"
                                end
                            end
                        end
        
                        message << "*Message type*"
                        types = rows.type_message.uniq.sort
                        types.each do |type|
                            count = rows.count {|h| h.type_message==type}
                            message << "\t#{type}: #{count} (#{(count.to_f*100/total).round(2)}%)"
                        end

                        if on_dm_master
                            message << "*Last activity*: #{rows[-1].date} #{rows[-1].bot_channel} #{rows[-1].type_message} #{rows[-1].user_name} #{rows[-1].command}"
                        end
                        if users_attachment.size>0
                            send_file(dest, "", 'users.txt', "", 'text/plain', "text", content: users_attachment.join("\n"))
                        end
                        if commands_attachment.size>0
                            send_file(dest, "", 'commands.txt', "", 'text/plain', "text", content: commands_attachment.join("\n"))
                        end
                        if channels_dest_attachment.size>0
                            send_file(dest, "", 'channels_dest.txt', "", 'text/plain', "text", content: channels_dest_attachment.join("\n"))
                        end
                    end
                end
            else
                message<<"Only Master admin users on a private conversation with the bot can see this kind of bot stats."
            end
        end
        respond "#{message.join("\n")}", dest
    end
end