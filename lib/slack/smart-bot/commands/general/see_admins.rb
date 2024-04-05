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
    team_id_admins = []
    channels = get_channels()
    channel_found = channels.detect { |c| c.id == channel }
    if !channel_found.nil? and channel_found.creator.to_s != ''
      messages << "*Channel creator*: <@#{channel_found.creator}>"
      creator_info = find_user(channel_found.creator)
    else
      creator_info = {name: [], team_id: []}
    end
    messages << "*Master admins*: <@#{config.masters.join('>, <@')}>"
    if Thread.current[:typem] == :on_bot or Thread.current[:typem] == :on_master
      admins = config.admins.dup
      team_id_admins = config.team_id_admins.dup
    end
    if @admins_channels.key?(channel) and @admins_channels[channel].size > 0
      team_id_admins = (@admins_channels[channel] + team_id_admins).uniq
      admins = (@admins_channels[channel].map { |a| a.split('_')[1..-1].join('_') } + admins).uniq
    end
    admins = admins - config.masters - [creator_info.name]
    team_id_admins = team_id_admins - config.team_id_masters - ["#{creator_info.team_id}_#{creator_info.name}"]
    messages << "*Admins*: <@#{admins.join('>, <@')}>" unless admins.empty?
    respond messages.join("\n")
  end
end
