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
    # help: `bot stats today`
    # help: `bot stats exclude COMMAND_ID`
    # help: `bot stats monthly`
    # help: `bot stats alldata`
    # help:    To see the bot stats
    # helpmaster:    You can use this command only if you are a Master admin user and if you are in a private conversation with the bot
    # helpmaster:    You need to set stats to true to generate the stats when running the bot instance.
    # help:    If alldata option supplied then it will be attached files including all data and not only the top 10.
    # help:    Examples:
    # help:      _bot stats #sales_
    # helpmaster:      _bot stats @peter.wind_
    # help:      _bot stats #sales from 2019/12/15 to 2019/12/31_
    # help:      _bot stats #sales today_
    # help:      _bot stats #sales from 2020-01-01 monthly_
    # help:      _bot stats exclude routines masters from 2021/01/01 monthly_
    # help:    <https://github.com/MarioRuiz/slack-smart-bot#bot-management|more info>
    # help:
    def bot_stats(dest, from_user, typem, channel_id, from, to, user, st_command, exclude_masters, exclude_routines, exclude_command, monthly, all_data)
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
                if from[0..3]=='2020' # this was an issue only on that period
                    Dir["#{config.stats_path}.*.log"].sort.each do |file|
                        if file >= "#{config.stats_path}.#{from_file}.log" or file <= "#{config.stats_path}.#{to_file}.log"
                            CSV.foreach(file, headers: true, header_converters: :symbol, converters: :numeric) do |row|
                                unless users_id_name.key?(row[:user_id])
                                    users_id_name[row[:user_id]] = row[:user_name]
                                end
                                unless users_name_id.key?(row[:user_name])
                                    users_name_id[row[:user_name]] = row[:user_id]
                                end
        
                            end
                        end
                    end
                end
    
                if user!=''
                    user_info = @users.select{|u| u.id == user}[-1]
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
                                            if row[:bot_channel_id] == channel_id or channel_id == ''
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
                            message << "\t#{channel}: #{count} (#{(count.to_f*100/total).round(2)}%)"
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
                        message << "\t#{ch}: #{count_channels_dest[ch]} (#{(count_channels_dest[ch].to_f*100/total).round(2)}%)"
                    end
                    if count_channels_dest.size > 10 and all_data
                        count_channels_dest.each do |ch, value|
                            channels_dest_attachment << "\t#{ch}: #{value} (#{(value.to_f*100/total).round(2)}%)"
                        end
                    end


                    users_attachment = []
                    if user==''
                        users = rows.user_id.uniq.sort
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
                        count_user.sort_by {|k,v| -v}.each do |user, count|
                            i+=1
                            if i <= 10
                                message << "\t#{users_id_name[user]}: #{count} (#{(count.to_f*100/total).round(2)}%)"
                            end
                            if users.size > 10 and all_data
                                users_attachment << "\t#{users_id_name[user]}: #{count} (#{(count.to_f*100/total).round(2)}%)"
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
        respond "#{message.join("\n")}", dest
    end
end