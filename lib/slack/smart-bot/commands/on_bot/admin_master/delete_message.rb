class SlackSmartBot

    # helpadmin: ----------------------------------------------
    # helpadmin: `delete message URL`
    # helpadmin:    It will delete the SmartBot message supplied
    # helpadmin:    You can use this command only if you are a Master admin user and if you are in a private conversation with the bot
    # helpadmin: command_id: :delete_message
    # helpadmin:
    def delete_message(from, typem, url)
      save_stats(__method__)
      channel, ts = url.scan(/\/archives\/(\w+)\/(\w\d+)/)[0]
      if config.masters.include?(from) and typem==:on_dm and !channel.nil? #master admin user
        ts = "#{ts[0..-7]}.#{ts[-6..-1]}"
        succ = delete(channel, ts)
        if succ
          react :heavy_check_mark
        else
          react :x
        end
      else
        respond "Only master admin users on a private conversation with the SmartBot can delete SmartBot messages"
      end
    end
end
  