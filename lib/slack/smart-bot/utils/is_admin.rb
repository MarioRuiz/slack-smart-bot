class SlackSmartBot
    def is_admin?(user=nil)
        if user.nil?
            user = Thread.current[:user]
            team_id_user_name = "#{user.team_id}_#{user.name}"
        elsif user.is_a?(String) and user.match?(/^[A-Z0-9]{7,11}_/)
            team_id = user.split('_')[0]
            user_name = user.split('_')[1..-1].join('_')
            team_id_user_name = "#{team_id}_#{user_name}"
        elsif user.is_a?(String)
            team_id_user_name = "#{config.team_id}_#{user}"
        else
            team_id_user_name = "#{user.team_id}_#{user.name}"
        end

        if (Thread.current[:dchannel].to_s!='' and Thread.current[:dchannel][0]!='D' and !@channels_creator.key?(Thread.current[:dchannel])) or
            (Thread.current[:dest].to_s!='' and Thread.current[:dest][0]!='D' and !@channels_creator.key?(Thread.current[:dest])) or
            (Thread.current[:using_channel].to_s!='' and !@channels_creator.key?(Thread.current[:using_channel]))
            get_channels_name_and_id()
        end

        if config.team_id_masters.include?(team_id_user_name) or
           config.team_id_admins.include?(team_id_user_name) or
           (Thread.current[:typem] == :on_call and @admins_channels.key?(Thread.current[:dchannel]) and @admins_channels[Thread.current[:dchannel]].include?(team_id_user_name)) or
           (Thread.current[:using_channel].to_s == '' and @admins_channels.key?(Thread.current[:dest]) and @admins_channels[Thread.current[:dest]].include?(team_id_user_name)) or
           (@admins_channels.key?(Thread.current[:using_channel]) and @admins_channels[Thread.current[:using_channel]].include?(team_id_user_name)) or
           (Thread.current[:using_channel].to_s=='' and @channels_creator.key?(Thread.current[:dest]) and team_id_user_name == @channels_creator[Thread.current[:dest]]) or
           (Thread.current[:typem] == :on_call  and @channels_creator.key?(Thread.current[:dchannel]) and team_id_user_name == @channels_creator[Thread.current[:dchannel]]) or
           (@channels_creator.key?(Thread.current[:using_channel]) and team_id_user_name == @channels_creator[Thread.current[:using_channel]])
            return true
        else
            return false
        end
    end
end
