class SlackSmartBot

  def see_announcements(user, type, channel, mention=false, publish=false)
    save_stats(__method__)
    typem = Thread.current[:typem]
    general_message = ""
    if channel == ''
      if typem == :on_call
        channel = Thread.current[:dchannel]
      else
        channel = Thread.current[:dest]
      end
    end
    if publish
      dest = channel
    else
      dest = Thread.current[:dest]
    end
    
    if type == 'all'
      if config.masters.include?(user.name) and typem==:on_dm
        channels = Dir.entries("#{config.path}/announcements/")
        channels.select! {|i| i[/\.csv$/]}
      else
        channels = []
        respond "Only master admins on a DM with the SmarBot can call this command.", dest
      end
    elsif typem == :on_dm and channel == Thread.current[:dest]
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
      if has_access?(__method__, user)
        if (channel_id!=Thread.current[:dest] and config.masters.include?(user.name) and typem==:on_dm) or publish
          see_announcements_on_demand = true
        else
          see_announcements_on_demand = false
        end
        if channel_id == Thread.current[:dest] or see_announcements_on_demand or publish #master admin user or publish_announcements
          if File.exist?("#{config.path}/announcements/#{channel_id}.csv") and (!@announcements.key?(channel_id) or see_announcements_on_demand) # to force to have the last version that maybe was updated by other SmartBot in case of demand
            t = CSV.table("#{config.path}/announcements/#{channel_id}.csv", headers: ['message_id', 'user_deleted', 'user_created', 'date', 'time', 'type', 'message'])
            @announcements[channel_id] = t
          end
          if @announcements.key?(channel_id)
            message = []
            @announcements[channel_id].each do |m|
              if m[:user_deleted] == '' and (type == 'all' or type == '' or type==m[:type])
                if m[:type].match?(/:[\w\-]+:/)
                  emoji = m[:type]
                elsif m[:type] == 'white'
                  emoji = ':white_square:'
                else
                  emoji = ":large_#{m[:type]}_square:"
                end
                if mention
                  user_created = "<@#{m[:user_created]}>"
                else
                  user_created = m[:user_created]
                  user_info = @users.select { |u| u.name == user_created or (u.key?(:enterprise_user) and u.enterprise_user.name == user_created) }[-1]
                  user_created = user_info.profile.display_name unless user_info.nil?
                end
                if type == 'all' and channel_id[0]=='D'
                  message << "\t#{emoji} *private* _(id:#{m[:message_id]} - #{m[:date]} #{m[:time]})_"
                else
                  message << "\t#{emoji} #{m[:message]} _(id:#{m[:message_id]} - #{m[:date]} #{m[:time]} #{user_created})_"
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
              message << general_message unless general_message.empty?
              respond message.join("\n"), dest, unfurl_links: false, unfurl_media: false
            else
              if typem == :on_dm and channel_id[0]=='D'
                respond("There are no #{type} announcements#{general_message}", dest) unless type == 'all'
              else
                respond("There are no #{type} announcements for <##{channel_id}>#{general_message}", dest) unless publish or type == 'all' or (typem==:on_dm and channel_id[0]!='D' and !see_announcements_on_demand)
              end
            end
          else
            if typem == :on_dm and channel_id[0]=='D'
              respond("There are no announcements#{general_message}", dest) unless type == 'all'
            else
              respond("There are no announcements for <##{channel_id}>#{general_message}", dest) unless publish or type == 'all' or (typem==:on_dm and channel_id[0]!='D' and !see_announcements_on_demand)
            end
          end
        else
          respond "Go to <##{channel_id}> and call the command from there.", dest
        end
      end
    end
  end
end
