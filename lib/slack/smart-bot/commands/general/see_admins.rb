class SlackSmartBot
  def see_admins()
    save_stats(__method__)
    if Thread.current[:typem] == :on_call
      channel = Thread.current[:dchannel]
    elsif Thread.current[:using_channel].to_s==''
      channel = Thread.current[:dest]
    else
      channel = Thread.current[:using_channel]
    end

    messages = []
    admins = []
    channels = get_channels()
    channel_found = channels.detect { |c| c.id == channel }
    if !channel_found.nil? and channel_found.creator.to_s != ''
      messages << "*Channel creator*: <@#{channel_found.creator}>" 
      creator_info = @users.select{|u| u.id == channel_found.creator or (u.key?(:enterprise_user) and u.enterprise_user.id == channel_found.creator)}[-1]
    else
      creator_info = {name: []}
    end
    messages << "*Master admins*: <@#{config.masters.join('>, <@')}>"
    if Thread.current[:typem] == :on_bot or Thread.current[:typem] == :on_master
      admins = config.admins.dup
    end
    if @admins_channels.key?(channel) and @admins_channels[channel].size > 0
      admins = (@admins_channels[channel] + admins).uniq
    end
    admins = admins - config.masters - [creator_info.name]
    messages << "*Admins*: <@#{admins.join('>, <@')}>" unless admins.empty?
    respond messages.join("\n")
  end
end
