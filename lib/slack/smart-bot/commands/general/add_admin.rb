class SlackSmartBot
  def add_admin(user, admin_user)
    save_stats(__method__)
    if Thread.current[:dest][0]=='D'
      respond "This command cannot be called from a DM"
    else
      if Thread.current[:typem] == :on_call
        channel = Thread.current[:dchannel]
      elsif Thread.current[:using_channel].to_s==''
        channel = Thread.current[:dest]
      else
        channel = Thread.current[:using_channel]
      end
      messages = []
      admins = config.masters.dup
      team_id_admins = config.team_id_masters.dup

      channels = get_channels()
      channel_found = channels.detect { |c| c.id == channel }
      if !channel_found.nil? and channel_found.creator.to_s != ''
        creator_info = find_user(channel_found.creator)
        admins << creator_info.name
        team_id_admins << "#{creator_info.team_id}_#{creator_info.name}"
      end
      if Thread.current[:typem] == :on_bot or Thread.current[:typem] == :on_master
        admins << config.admins.dup
        team_id_admins << config.team_id_admins.dup
      end
      if @admins_channels.key?(channel) and @admins_channels[channel].size > 0
        team_id_admins << @admins_channels[channel]
        #remove the team_id from the names on @admins_channels
        admins << @admins_channels[channel].map { |a| a.split('_')[1..-1].join('_') }
      end
      admins.flatten!
      admins.uniq!
      admins.delete(nil)
      team_id_admins.flatten!
      team_id_admins.uniq!
      team_id_admins.delete(nil)
      if team_id_admins.include?("#{user.team_id}_#{user.name}")
        admin_info = find_user(admin_user)
        if team_id_admins.include?("#{admin_info.team_id}_#{admin_info.name}")
          messages << "This user is already an admin of this channel."
        else
          @admins_channels[channel] ||= []
          @admins_channels[channel] << "#{admin_info.team_id}_#{admin_info.name}"
          update_admins_channels()
          messages << "The user is an admin of this channel from now on."
          admins << admin_info.name
          team_id_admins << "#{admin_info.team_id}_#{admin_info.name}"
        end
        messages << "*Admins*: <@#{admins.join('>, <@')}>"
      else
        messages << "Only the creator of the channel, Master admins or admins can add a new admin for this channel."
        messages << "*Admins*: <@#{admins.join('>, <@')}>"
      end

      respond messages.join("\n")
    end
  end
end
