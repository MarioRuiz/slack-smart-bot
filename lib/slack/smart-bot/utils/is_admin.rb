class SlackSmartBot
    def is_admin?(from=nil)
        if from.nil?
            user = Thread.current[:user]
            from = user.name
        end
        
        if (Thread.current[:dchannel].to_s!='' and Thread.current[:dchannel][0]!='D' and !@channels_creator.key?(Thread.current[:dchannel])) or 
            (Thread.current[:dest].to_s!='' and Thread.current[:dest][0]!='D' and !@channels_creator.key?(Thread.current[:dest])) or 
            (Thread.current[:using_channel].to_s!='' and !@channels_creator.key?(Thread.current[:using_channel]))
            get_channels_name_and_id() 
        end

        if config.masters.include?(from) or 
           config.admins.include?(from) or 
           (Thread.current[:typem] == :on_call and @admins_channels.key?(Thread.current[:dchannel]) and @admins_channels[Thread.current[:dchannel]].include?(from)) or
           (Thread.current[:using_channel].to_s == '' and @admins_channels.key?(Thread.current[:dest]) and @admins_channels[Thread.current[:dest]].include?(from)) or
           (@admins_channels.key?(Thread.current[:using_channel]) and @admins_channels[Thread.current[:using_channel]].include?(from)) or 
           (Thread.current[:using_channel].to_s=='' and @channels_creator.key?(Thread.current[:dest]) and from == @channels_creator[Thread.current[:dest]]) or 
           (Thread.current[:typem] == :on_call  and @channels_creator.key?(Thread.current[:dchannel]) and from == @channels_creator[Thread.current[:dchannel]]) or 
           (@channels_creator.key?(Thread.current[:using_channel]) and from == @channels_creator[Thread.current[:using_channel]])
            return true
        else
            return false
        end
    end
end