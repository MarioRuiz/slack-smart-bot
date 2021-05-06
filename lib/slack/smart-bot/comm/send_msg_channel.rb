class SlackSmartBot

  # to: (String) Channel name or id
  # msg: (String) message to send
  def send_msg_channel(to, msg)
    unless msg == ""
      begin
        get_channels_name_and_id() unless @channels_name.key?(to) or @channels_id.key?(to)
        if @channels_name.key?(to) #it is an id
          channel_id = to
        elsif @channels_id.key?(to) #it is a channel name
          channel_id = @channels_id[to]
        else
          @logger.fatal "Channel: #{to} not found. Message: #{msg}"
        end
        if config[:simulate]
          open("#{config.path}/buffer_complete.log", "a") { |f|
            f.puts "|#{channel_id}|#{config[:nick_id]}|#{config[:nick]}|#{msg}~~~"
          }
        else  
          if Thread.current[:on_thread]
            client.message(channel: channel_id, text: msg, as_user: true, thread_ts: Thread.current[:thread_ts])
          else
            client.message(channel: channel_id, text: msg, as_user: true)
          end
        end
        if config[:testing] and config.on_master_bot
          open("#{config.path}/buffer.log", "a") { |f|
            f.puts "|#{channel_id}|#{config[:nick_id]}|#{config[:nick]}|#{msg}"
          }
        end
      rescue Exception => stack
        @logger.warn stack
      end
    end
  end

end
