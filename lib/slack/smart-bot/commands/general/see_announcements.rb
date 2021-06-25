class SlackSmartBot

  def see_announcements(user, type, channel)
    save_stats(__method__)
    channel = Thread.current[:dest] if channel == ''
    typem = Thread.current[:typem]
    
    if type == 'all'
      if config.masters.include?(user.name) and typem==:on_dm
        channels = Dir.entries("#{config.path}/announcements/")
        channels.select! {|i| i[/\.csv$/]}
      else
        channels = []
        respond "Only master admins on a DM with the SmarBot can call this command."
      end
    elsif typem == :on_dm
      channels = [channel, @channel_id]
    else
      channels = [channel]
    end
    channels.each do |channel|
      channel.gsub!('.csv','')
      if channel[0]== 'D'
        channel_id = channel
      else
        get_channels_name_and_id() unless @channels_name.keys.include?(channel) or @channels_id.keys.include?(channel)
        channel_id = nil
        if @channels_name.key?(channel) #it is an id
          channel_id = channel
          channel = @channels_name[channel_id]
        elsif @channels_id.key?(channel) #it is a channel name
          channel_id = @channels_id[channel]
        end
      end
      if config[:allow_access].key?(__method__) and !config[:allow_access][__method__].include?(user.name) and !config[:allow_access][__method__].include?(user.id) and 
        (!user.key?(:enterprise_user) or ( user.key?(:enterprise_user) and !config[:allow_access][__method__].include?(user[:enterprise_user].id)))
        respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
      else
        if channel_id == Thread.current[:dest] or (channel_id!=Thread.current[:dest] and config.masters.include?(user.name) and typem==:on_dm) #master admin user
          if File.exists?("#{config.path}/announcements/#{channel_id}.csv") and !@announcements.key?(channel_id)
            t = CSV.table("#{config.path}/announcements/#{channel_id}.csv", headers: ['message_id', 'user_deleted', 'user_created', 'date', 'time', 'type', 'message'])
            @announcements[channel_id] = t
          end
          if @announcements.key?(channel_id)
            message = []
            @announcements[channel_id].each do |m|
              if m[:user_deleted] == '' and (type == 'all' or type == '' or type==m[:type])
                if type == 'all' and channel_id[0]=='D'
                  message << "\t#{m[:message_id]} :#{"large_" if m[:type]!='white'}#{m[:type]}_square: #{m[:date]} #{m[:time]} > *private*"
                else
                  message << "\t#{m[:message_id]} :#{"large_" if m[:type]!='white'}#{m[:type]}_square: #{m[:date]} #{m[:time]} > #{m[:message]} #{"(#{m[:user_created]})" unless channel_id[0]=='D'}"
                end
              end
            end
            if message.size > 0
              if channel_id[0]=='D'
                if type == 'all'
                  message.unshift("*Private messages stored on DM with the SmartBot and <@#{@announcements[channel_id][:user_created][0]}>*")
                else
                  message.unshift("*Private messages stored on your DM with the SmartBot*")
                end
              else
                message.unshift("*Announcements for channel <##{channel_id}>*")
              end
              respond message.join("\n")
            else
              if typem == :on_dm and channel_id[0]=='D'
                respond "There are no #{type} announcements" unless type == 'all'
              else
                respond "There are no #{type} announcements for <##{channel_id}>" unless type == 'all' or (typem==:on_dm and channel_id[0]!='D')
              end
            end
          else
            if typem == :on_dm and channel_id[0]=='D'
              respond "There are no announcements" unless type == 'all'
            else
              respond "There are no announcements for <##{channel_id}>" unless type == 'all' or (typem==:on_dm and channel_id[0]!='D')
            end
          end
        else
          respond "Go to <##{channel_id}> and call the command from there."
        end
      end
    end
  end
end
