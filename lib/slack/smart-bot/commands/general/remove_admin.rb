class SlackSmartBot
  def remove_admin(user, admin_user)
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
      channels = get_channels()
      channel_found = channels.detect { |c| c.id == channel }
      if !channel_found.nil? and channel_found.creator.to_s != ''
        creator_info = @users.select{|u| u.id == channel_found.creator or (u.key?(:enterprise_user) and u.enterprise_user.id == channel_found.creator)}[-1]
        admins << creator_info.name
      end
      if Thread.current[:typem] == :on_bot or Thread.current[:typem] == :on_master
        admins << config.admins.dup
      end
      if @admins_channels.key?(channel) and @admins_channels[channel].size > 0
        admins << @admins_channels[channel]
      end
      admins.flatten!
      admins.uniq!
      admins.delete(nil)
      if admins.include?(user.name)
        admin_info = @users.select{|u| u.id == admin_user or (u.key?(:enterprise_user) and u.enterprise_user.id == admin_user)}[-1]
        if creator_info.name == admin_info.name
          messages << "This user created the channel and cannot be removed as an admin."
        elsif config.masters.include?(admin_info.name) or config.masters.include?(admin_user)
          messages << "Master admins cannot be removed as admins of this channel."
        elsif config.admins.include?(admin_info.name) or config.admins.include?(admin_user)
          messages << "This user is a defaulted admin for this channel and cannot be removed using this command."
        elsif !admins.include?(admin_info.name)
          messages << "This user is not an admin of this channel."
        else
          @admins_channels[channel] ||= []
          @admins_channels[channel].delete(admin_info.name)
          update_admins_channels()
          messages << "The user is not an admin of this channel from now on."
          admins.delete(admin_info.name)
        end
        messages << "*Admins*: <@#{admins.join('>, <@')}>"
      else
        messages << "Only the creator of the channel, Master admins or admins can remove an admin of this channel."
        messages << "*Admins*: <@#{admins.join('>, <@')}>"
      end

      respond messages.join("\n")
    end
  end
end
