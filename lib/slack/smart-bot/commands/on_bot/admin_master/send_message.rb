class SlackSmartBot

    # helpadmin: ----------------------------------------------
    # helpadmin: `send message to @USER_NAME : MESSAGE`
    # helpadmin: `send message to #CHANNEL_NAME : MESSAGE`
    # helpadmin: `send message to THREAD_ID : MESSAGE`
    # helpadmin: `send message to URL : MESSAGE`
    # helpadmin: `send message to @USER1 @USER99 : MESSAGE`
    # helpadmin: `send message to #CHANNEL1 #CHANNEL99 : MESSAGE`
    # helpadmin:    It will send the specified message as SmartBot
    # helpadmin:    You can use this command only if you are a Master admin user and if you are in a private conversation with the bot
    # helpadmin: command_id: :send_message
    # helpadmin:
    def send_message(dest, from, typem, to, thread_ts, message)
      save_stats(__method__)
      if config.masters.include?(from) and typem==:on_dm #master admin user
        unless Thread.current[:command_orig].to_s == ''
          message_orig = Thread.current[:command_orig].to_s.gsub("\u00A0", " ").scan(/[^:]+\s*:\s+(.+)/im).join
          message = message_orig unless message_orig == ''
        end
        succ = true
        to.each do |t|
          unless t.match?(/^\s*$/)
            succ = (respond message, t, thread_ts: thread_ts, web_client: true) && succ
          end
        end
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
  