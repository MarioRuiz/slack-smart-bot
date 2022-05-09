class SlackSmartBot
    # help: ----------------------------------------------
    # help: `leaderboard`
    # help: `ranking`
    # help: `podium`
    # help: `leaderboard from YYYY/MM/DD`
    # help: `leaderboard from YYYY/MM/DD to YYYY/MM/DD`
    # help: `leaderboard PERIOD`
    # help:    It will present some useful information about the use of the SmartBot in the period specified.
    # help:    If no 'from' and 'to' specified then it will be considered 'last week'
    # help:    PERIOD: today, yesterday, last week, this week, last month, this month, last year, this year
    # help:    The results will exclude master admins and routines.
    # help:    For a more detailed data use the command `bot stats`
    # help:    Examples:
    # help:      _leaderboard_
    # help:      _podium from 2021/05/01_
    # help:      _leaderboard from 2021/05/01 to 2021/05/31_
    # help:      _ranking today_
    # help:    <https://github.com/MarioRuiz/slack-smart-bot#bot-management|more info>
    # help: command_id: :leaderboard
    # help: 
    
    def leaderboard(from, to, period)
        exclude_masters = true
        exclude_routines = true
        require 'csv'
        if config.stats
            message = []
        else
            message = ["You need to set stats to true to generate the stats when running the bot instance."]
        end
        save_stats(__method__)
        if !File.exist?("#{config.stats_path}.#{Time.now.strftime("%Y-%m")}.log")
            message<<'No stats'
        else
            if period == ''
                message << "*Leaderboard SmartBot <##@channel_id> from #{from} to #{to}*\n"
            else
                message << "*Leaderboard SmartBot <##@channel_id> #{period}* (#{from} -> #{to})\n"
            end
            from_short = from
            to_short = to
            from_file = from[0..3] + '-' + from[5..6]
            to_file = to[0..3] + '-' + to[5..6]
            from+= " 00:00:00 +0000"
            to+= " 23:59:59 +0000"
            rows = []
            users_id_name = {}
            users_name_id = {}
            count_users = {}
            count_channels_dest = {}
            count_commands_uniq_user = {}

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
                                if row[:bot_channel_id] == @channel_id
                                    if row[:date] >= from and row[:date] <= to
                                        count_users[row[:user_id]] ||= 0
                                        count_users[row[:user_id]] += 1
                                        rows << row.to_h
                                        count_channels_dest[row[:dest_channel]] ||= 0
                                        count_channels_dest[row[:dest_channel]] += 1
                                        count_commands_uniq_user[row[:user_id]] ||= []
                                        count_commands_uniq_user[row[:user_id]] << row[:command] unless count_commands_uniq_user[row[:user_id]].include?(row[:command])
                                    end
                                end
                            end
                        end
                    end
                end
            end

            total = rows.size

            if total > 0

                users = rows.user_id.uniq.sort
                count_user = {}
                users.each do |user|
                    count = rows.count {|h| h.user_id==user}
                    count_user[user] = count
                end
                mtc = nil
                mtu = []
                i = 0
                count_user.sort_by {|k,v| -v}.each do |user, count|
                    if i >= 3
                        break
                    elsif mtc.nil? or mtc == count or i < 3
                        mtu << "*<@#{users_id_name[user]}>* (#{count})"
                        mtc = count
                    else 
                        break
                    end
                    i+=1
                end
                message << "\t :boom: Users that called more commands: \n\t\t\t\t#{mtu.join("\n\t\t\t\t")}"

                mtc = nil
                mtu = []
                i = 0
                count_commands_uniq_user.sort_by {|k,v| -v.size}.each do |user, cmds|
                    if i >= 3
                        break
                    elsif mtc.nil? or mtc == cmds.size or i < 3
                        mtu << "*<@#{users_id_name[user]}>* (#{cmds.size})"
                        mtc = cmds.size
                    else 
                        break
                    end
                    i+=1
                end
                message << "\t :stethoscope: Users that called more different commands: \n\t\t\t\t#{mtu.join("\n\t\t\t\t")}"
                
                commands_attachment = []

                commands = rows.command.uniq.sort
                count_command = {}
                commands.each do |command|
                    count = rows.count {|h| h.command==command}
                    count_command[command] = count
                end
                
                mtu = []
                count_command.sort_by {|k,v| -v}[0..2].each do |command, count|
                    mtu << "*`#{command.gsub('_',' ')}`* (#{count})"
                end
                message << "\t :four_leaf_clover: Most used commands: \n\t\t\t\t#{mtu.join("\n\t\t\t\t")}"

                count_channels_dest = count_channels_dest.sort_by(&:last).reverse.to_h
                count_channels_dest.keys[0..0].each do |ch|
                    if ch=='DM'
                        message << "\t :star: Most used channel: *DM* (#{(count_channels_dest[ch].to_f*100/total).round(2)}%)"
                    else
                        message << "\t :star: Most used channel: *<##{@channels_id[ch]}>* (#{(count_channels_dest[ch].to_f*100/total).round(2)}%)"
                    end
                end
                
                types = rows.type_message.uniq.sort
                count_type = {}
                types.each do |type|
                    count = rows.count {|h| h.type_message==type}
                    count_type[type] = count
                end
                
                count_type.sort_by {|k,v| -v}[0..0].each do |type, count|
                    message << "\t :house_with_garden: Most calls came from *#{type}* (#{(count.to_f*100/total).round(2)}%)"
                end
            else
                message << 'No data yet'
            end
        end
        respond "#{message.join("\n")}"

    end
end