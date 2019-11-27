class SlackSmartBot

  def get_channels_name_and_id
    #todo: add pagination for case more than 1000 channels on the workspace
    channels = client.web_client.conversations_list(
      types: "private_channel,public_channel",
      limit: "1000",
      exclude_archived: "true",
    ).channels

    @channels_id = Hash.new()
    @channels_name = Hash.new()
    channels.each do |ch|
      unless ch.is_archived
        @channels_id[ch.name] = ch.id
        @channels_name[ch.id] = ch.name
      end
    end
  end

end
