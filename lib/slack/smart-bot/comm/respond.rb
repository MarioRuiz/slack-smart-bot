class SlackSmartBot
  def respond(msg, dest = nil)
    if dest.nil? and Thread.current.key?(:dest)
      dest = Thread.current[:dest]
    end
    dest = @channels_id[dest] if @channels_id.key?(dest) #it is a name of channel
    if !config.simulate #https://api.slack.com/docs/rate-limits
      msg.to_s.size > 500 ? wait = 0.5 : wait = 0.1
      sleep wait if Time.now <= (@last_respond+wait) 
    end
    if dest.nil?
      if config[:simulate]
        open("#{config.path}/buffer_complete.log", "a") { |f|
          f.puts "|#{@channel_id}|#{config[:nick_id]}|#{config[:nick]}|#{msg}~~~"
        }
      else  
        if Thread.current[:on_thread]
          client.message(channel: @channel_id, text: msg, as_user: true, thread_ts: Thread.current[:thread_ts])
        else
          client.message(channel: @channel_id, text: msg, as_user: true)
        end
      end
      if config[:testing] and config.on_master_bot
        open("#{config.path}/buffer.log", "a") { |f|
          f.puts "|#{@channel_id}|#{config[:nick_id]}|#{config[:nick]}|#{msg}"
        }
      end
    elsif dest[0] == "C" or dest[0] == "G" # channel
      if config[:simulate]
        open("#{config.path}/buffer_complete.log", "a") { |f|
        f.puts "|#{dest}|#{config[:nick_id]}|#{config[:nick]}|#{msg}~~~"
      }
      else  
        if Thread.current[:on_thread]
          client.message(channel: dest, text: msg, as_user: true, thread_ts: Thread.current[:thread_ts])
        else
          client.message(channel: dest, text: msg, as_user: true)
        end
      end
      if config[:testing] and config.on_master_bot
        open("#{config.path}/buffer.log", "a") { |f|
          f.puts "|#{dest}|#{config[:nick_id]}|#{config[:nick]}|#{msg}"
        }
      end
    elsif dest[0] == "D" or dest[0] == "U"  or dest[0] == "W" # Direct message
      send_msg_user(dest, msg)
    elsif dest[0] == "@"
      begin
        user_info = get_user_info(dest)
        send_msg_user(user_info.user.id, msg)
      rescue Exception => stack
        @logger.warn("user #{dest} not found.")
        @logger.warn stack
        if Thread.current.key?(:dest)
          respond("User #{dest} not found.")
        end
      end
    else
      @logger.warn("method respond not treated correctly: msg:#{msg} dest:#{dest}")
    end
    @last_respond = Time.now
  end

end
