def get_channel_members(channel_id)
    if config.simulate and config.key?(:client)
        client.web_client.conversations_members[channel_id.to_sym].members
    else
        client.web_client.conversations_members(channel: channel_id).members
    end

end
