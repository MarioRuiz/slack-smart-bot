def get_channels(bot_is_in: false, types: 'private_channel,public_channel')
  begin
    if config.simulate and config.key?(:client)
      if bot_is_in
        client.web_client.conversations_members.reject { |r, v| !v.members.include?(config.nick_id) }.values
      else
        client.web_client.conversations_members.values
      end
    else
      if bot_is_in
        client.web_client.users_conversations(exclude_archived: true, limit: 1000, types: "im, public_channel,private_channel").channels
      else
        resp = client.web_client.conversations_list(types: types, limit: "1000", exclude_archived: "true")
        channels = resp.channels
        while resp.response_metadata.next_cursor.to_s != ""
          resp = client.web_client.conversations_list(
            cursor: resp.response_metadata.next_cursor.to_s,
            types: types,
            limit: "1000",
            exclude_archived: "true",
          )
          channels += resp.channels
        end        
        return channels
      end
    end
  rescue Exception => stack
    @logger.warn stack
    return []
  end
end
