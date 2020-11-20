class SlackSmartBot
    # helpadmin: ----------------------------------------------
    # helpadmin: `bot stats`
    # helpadmin: `bot stats USER_NAME`
    # helpadmin: `bot stats exclude masters`
    # helpadmin: `bot stats exclude routines`
    # helpadmin: `bot stats from YYYY/MM/DD`
    # helpadmin: `bot stats from YYYY/MM/DD to YYYY/MM/DD`
    # helpadmin: `bot stats CHANNEL`
    # helpadmin: `bot stats CHANNEL from YYYY/MM/DD`
    # helpadmin: `bot stats CHANNEL from YYYY/MM/DD to YYYY/MM/DD`
    # helpadmin: `bot stats USER_NAME from YYYY/MM/DD to YYYY/MM/DD`
    # helpadmin: `bot stats CHANNEL USER_NAME from YYYY/MM/DD to YYYY/MM/DD`
    # helpadmin: `bot stats CHANNEL exclude masters from YYYY/MM/DD to YYYY/MM/DD`
    # helpadmin: `bot stats today`
    # helpadmin: `bot stats exclude COMMAND_ID`
    # helpadmin: `bot stats monthly`
    # helpadmin: `bot stats alldata`
    # helpadmin:    To see the bot stats
    # helpadmin:    You can use this command only if you are a Master admin user and if you are in a private conversation with the bot
    # helpadmin:    You need to set stats to true to generate the stats when running the bot instance.
    # helpadmin:    If alldata option supplied then it will be attached files including all data for users and commands and not only the top 10.
    # helpadmin:    Examples:
    # helpadmin:      _bot stats #sales_
    # helpadmin:      _bot stats @peter.wind_
    # helpadmin:      _bot stats #sales from 2019/12/15 to 2019/12/31_
    # helpadmin:      _bot stats #sales today_
    # helpadmin:      _bot stats #sales from 2020-01-01 monthly_
    # helpadmin:      _bot stats exclude routines masters from 2021/01/01 monthly_
    # helpadmin:
    def bot_stats(dest, from_user, typem, channel_id, from, to, user, exclude_masters, exclude_routines, exclude_command, monthly, all_data)
        require 'csv'
        if config.stats
            message = []
        else
            message = ["You need to set stats to true to generate the stats when running the bot instance."]
        end
        save_stats(__method__)
        if (config.masters.include?(from_user) or @master_admin_users_id.include?(from_user)) and typem==:on_dm #master admin user
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
    
                # to translate global and enterprise users since sometimes was returning different names/ids
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
    
                if user!=''
                    user_info = get_user_info(user)
                    if users_id_name.key?(user_info.user.id)
                        user_name = users_id_name[user_info.user.id]
                    else
                        user_name = user_info.user.name
                    end
                    if users_name_id.key?(user_info.user.name)
                        user_id = users_name_id[user_info.user.name]
                    else
                        user_id = user_info.user.id
                    end
                end
                master_admins = config.masters.dup
                config.masters.each do |u|
                    if users_id_name.key?(u)
                        master_admins << users_id_name[u]
                    elsif users_name_id.key?(u)
                        master_admins << users_name_id[u]
                    end
                end
    
                Dir["#{config.stats_path}.*.log"].sort.each do |file|
                    if file >= "#{config.stats_path}.#{from_file}.log" or file <= "#{config.stats_path}.#{to_file}.log"
                        CSV.foreach(file, headers: true, header_converters: :symbol, converters: :numeric) do |row|
                            row[:date] = row[:date].to_s
                            row[:user_name] = users_id_name[row[:user_id]]
                            row[:user_id] = users_name_id[row[:user_name]]
                            if !exclude_masters or (exclude_masters and !master_admins.include?(row[:user_name]) and 
                                                    !master_admins.include?(row[:user_id]) and
                                                    !@master_admin_users_id.include?(row[:user_id]))
                                if !exclude_routines or (exclude_routines and !row[:user_name].match?(/^routine\//) )
                                    if user=='' or (user!='' and row[:user_name] == user_name) or (user!='' and row[:user_id] == user_id)
                                        if exclude_command == '' or (exclude_command!='' and row[:command]!=exclude_command)
                                            if row[:bot_channel_id] == channel_id or channel_id == ''
                                                if row[:date] >= from and row[:date] <= to
                                                    rows << row.to_h
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
                if user!=''
                    message << "Showing only user <@#{user}>"
                end
                if channel_id == ''
                    message << "*Total calls*: #{total} from #{from_short} to #{to_short}"
                else
                    message << "*Total calls <##{channel_id}>*: #{total} from #{from_short} to #{to_short}"
                end
                if total > 0
                    if monthly 
                        message << '*Totals by month / commands / users (%new)*'
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
                            message << "\t#{k}: #{v} (#{(v.to_f*100/total).round(2)}%) / #{commands_month[k].uniq.size} / #{users_month[k].uniq.size} #{message_new_users}"
                        end
                    end
    
                    if channel_id == ''
                        message << "*Channels*"
                        channels = rows.bot_channel.uniq.sort
                        channels.each do |channel|
                            count = rows.count {|h| h.bot_channel==channel}
                            message << "\t#{channel}: #{count} (#{(count.to_f*100/total).round(2)}%)"
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
    
                    message << "*Message type*"
                    types = rows.type_message.uniq.sort
                    types.each do |type|
                        count = rows.count {|h| h.type_message==type}
                        message << "\t#{type}: #{count} (#{(count.to_f*100/total).round(2)}%)"
                    end
                    message << "*Last activity*: #{rows[-1].date} #{rows[-1].bot_channel} #{rows[-1].type_message} #{rows[-1].user_name} #{rows[-1].command}"
                    if users_attachment.size>0
                        send_file(dest, "", 'users.txt', "", 'text/plain', "text", content: users_attachment.join("\n"))
                    end
                    if commands_attachment.size>0
                        send_file(dest, "", 'commands.txt', "", 'text/plain', "text", content: commands_attachment.join("\n"))
                    end
                end
            end
        else
            message<<"Only Master admin users on a private conversation with the bot can see the bot stats."
        end
        respond "#{message.join("\n")}", dest
    end
end