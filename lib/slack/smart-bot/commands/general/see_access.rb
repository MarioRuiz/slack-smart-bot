class SlackSmartBot
  def see_access(command_id)
    save_stats(__method__)
    if Thread.current[:typem] == :on_call
      channel = Thread.current[:dchannel]
    elsif Thread.current[:using_channel].to_s == ""
      channel = Thread.current[:dest]
    else
      channel = Thread.current[:using_channel]
    end
    command_ids = get_command_ids()
    if command_ids.values.flatten.include?(command_id)
      if @access_channels.key?(channel) and @access_channels[channel].key?(command_id) and @access_channels[channel][command_id].size > 0
        respond "Only these users have access to `#{command_id}` in this channel: <@#{@access_channels[channel][command_id].join(">, <@")}>"
      elsif @access_channels.key?(channel) and @access_channels[channel].key?(command_id) and @access_channels[channel][command_id].empty?
        respond "`#{command_id}` is not possible to be used in this channel. Please contact an admin if you want to use it."
      else
        respond "`#{command_id}` seems to be available in this channel."
      end
    else
      respond "It seems like #{command_id} is not valid. Please be sure that exists by calling `see command ids`"
    end
  end
end
