class SlackSmartBot

    # helpadmin: ----------------------------------------------
    # helpadmin: `send message to @USER_NAME : MESSAGE`
    # helpadmin: `send message to #CHANNEL_NAME : MESSAGE`
    # helpadmin: `send message to #CHANNEL_NAME THREAD_ID : MESSAGE`
    # helpadmin: `send message to URL : MESSAGE`
    # helpadmin:    It will send the specified message as SmartBot
    # helpadmin:    You can use this command only if you are a Master admin user and if you are in a private conversation with the bot
    # helpadmin:
    def send_message(dest, from, typem, to, thread_ts, message)
      save_stats(__method__)
      if config.masters.include?(from) and typem==:on_dm #master admin user
        succ = (respond message, to, thread_ts: thread_ts, web_client: true)
        if succ
          react :heavy_check_mark
        else
          react :x
        end
      else
        respond "Only master admin users on a private conversation with the SmartBot can send messages as SmartBot.", dest
      end
    end
end
  