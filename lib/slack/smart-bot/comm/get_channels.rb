def get_channels(bot_is_in: false)
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
        resp = {}
        next_cursor = ""
        begin
          resp.merge!(client.conversations_list(
            cursor: next_cursor,
            types: "private_channel, public_channel",
            limit: "1000",
            exclude_archived: "true",
          ))
          next_cursor = resp.response_metadata.next_cursor.to_s
        end until next_cursor == ""
        return resp.channels
      end
    end
  rescue Exception => stack
    @logger.warn stack
  end
end
