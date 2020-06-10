class SlackSmartBot
    # helpadmin: ----------------------------------------------
    # helpadmin: `bot stats`
    # helpadmin: `bot stats USER_NAME`
    # helpadmin: `bot stats exclude masters`
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
    # helpadmin:    To see the bot stats
    # helpadmin:    You can use this command only if you are a Master admin user and if you are in a private conversation with the bot
    # helpadmin:    You need to set stats to true to generate the stats when running the bot instance.
    # helpadmin:    Examples:
    # helpadmin:      _bot stats #sales_
    # helpadmin:      _bot stats @peter.wind_
    # helpadmin:      _bot stats #sales from 2019/12/15 to 2019/12/31_
    # helpadmin:      _bot stats #sales today_
    # helpadmin:      _bot stats #sales monthly_
    # helpadmin:
    def bot_stats(dest, from_user, typem, channel_id, from, to, user, exclude_masters, exclude_command, monthly)
        require 'csv'
        if config.stats
            message = []
        else
            message = ["You need to set stats to true to generate the stats when running the bot instance."]
        end
        save_stats(__method__)
        if config.masters.include?(from_user) and typem==:on_dm #master admin user
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

                Dir["#{config.stats_path}.*.log"].sort.each do |file|
                    if file >= "#{config.stats_path}.#{from_file}.log" or file <= "#{config.stats_path}.#{to_file}.log"
                        CSV.foreach(file, headers: true, header_converters: :symbol, converters: :numeric) do |row|
                            row[:date] = row[:date].to_s
                            if !exclude_masters or (exclude_masters and !config.masters.include?(row[:user_name]))
                                if user=='' or (user!='' and row[:user_id] == user)
                                    if exclude_command == '' or (exclude_command!='' and row[:command]!=exclude_command)
                                        if row[:bot_channel_id] == channel_id or channel_id == ''
                                            if row[:date] >= from and row[:date] <= to
                                                rows << row.to_h
                                                if monthly
                                                    rows_month[row[:date][0..6]] = 0 unless rows_month.key?(row[:date][0..6])
                                                    rows_month[row[:date][0..6]] += 1
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
                        message << '*Totals by month*'
                        rows_month.each do |k,v|
                            message << "\t#{k}: #{v} (#{(v.to_f*100/total).round(2)}%)"
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
                    if user==''
                        users = rows.user_name.uniq.sort
                        message << "*Users* - #{users.size}"
                        users.each do |user|
                            count = rows.count {|h| h.user_name==user}
                            message << "\t#{user}: #{count} (#{(count.to_f*100/total).round(2)}%)"
                        end
                    end

                    commands = rows.command.uniq.sort
                    message << "*Commands* - #{commands.size}"
                    commands.each do |command|
                        count = rows.count {|h| h.command==command}
                        message << "\t#{command}: #{count} (#{(count.to_f*100/total).round(2)}%)"
                    end

                    message << "*Message type*"
                    types = rows.type_message.uniq.sort
                    types.each do |type|
                        count = rows.count {|h| h.type_message==type}
                        message << "\t#{type}: #{count} (#{(count.to_f*100/total).round(2)}%)"
                    end
                    message << "*Last activity*: #{rows[-1].date} #{rows[-1].bot_channel} #{rows[-1].type_message} #{rows[-1].user_name} #{rows[-1].command}"
                end
                
            end
        else
            message<<"Only Master admin users on a private conversation with the bot can see the bot stats."
        end
        respond "#{message.join("\n")}", dest
    end
end