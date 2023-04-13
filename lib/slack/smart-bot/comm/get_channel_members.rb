class SlackSmartBot
    #todo: add pagination for case more than 1000 members in the channel
    def get_channel_members(channel_id)
        begin
            if channel_id.nil?
                return nil
            else
                if config.simulate and config.key?(:client)
                    client.web_client.conversations_members[channel_id.to_sym].members
                else
                    client.web_client.conversations_members(channel: channel_id, limit: 1000).members
                end
            end
        rescue Exception => stack
            @logger.warn stack
        end

    end
end