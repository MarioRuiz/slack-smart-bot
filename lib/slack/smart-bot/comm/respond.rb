class SlackSmartBot
  def respond(msg, dest = nil)
    begin
      msg = msg.to_s
      on_thread = Thread.current[:on_thread]
      if dest.nil? and Thread.current.key?(:dest)
        dest = Thread.current[:dest]
      elsif dest.is_a?(Symbol) and dest == :on_thread
        on_thread = true
        dest = Thread.current[:dest]
      elsif dest.is_a?(Symbol) and dest == :direct
        dest = Thread.current[:user].id
      end

      dest = @channels_id[dest] if @channels_id.key?(dest) #it is a name of channel
      if !config.simulate #https://api.slack.com/docs/rate-limits
        msg.size > 500 ? wait = 0.5 : wait = 0.1
        sleep wait if Time.now <= (@last_respond+wait)
      else
        wait = 0
      end

      msgs = [] # max of 4000 characters per message
      txt = ''
      msg.split("\n").each do |m|
        if (m+txt).size > 4000
          msgs << txt.chars.each_slice(4000).map(&:join) unless txt == ''
          txt = ''
        end
        txt+=(m+"\n")
      end
      msgs << txt
      msgs.flatten!
      
      if dest.nil?
        if config[:simulate]
          open("#{config.path}/buffer_complete.log", "a") { |f|
            f.puts "|#{@channel_id}|#{config[:nick_id]}|#{config[:nick]}|#{msg}~~~"
          }
        else  
          if on_thread
            msgs.each do |msg|
              client.message(channel: @channel_id, text: msg, as_user: true, thread_ts: Thread.current[:thread_ts])
              sleep wait
            end
          else
            msgs.each do |msg|
              client.message(channel: @channel_id, text: msg, as_user: true)
              sleep wait
            end
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
          if on_thread
            msgs.each do |msg|
              client.message(channel: dest, text: msg, as_user: true, thread_ts: Thread.current[:thread_ts])
              sleep wait
            end
          else
            msgs.each do |msg|
              client.message(channel: dest, text: msg, as_user: true)
              sleep wait
            end
          end
        end
        if config[:testing] and config.on_master_bot
          open("#{config.path}/buffer.log", "a") { |f|
            f.puts "|#{dest}|#{config[:nick_id]}|#{config[:nick]}|#{msg}"
          }
        end
      elsif dest[0] == "D" or dest[0] == "U"  or dest[0] == "W" # Direct message
        msgs.each do |msg|
          send_msg_user(dest, msg, on_thread)
          sleep wait
        end
      elsif dest[0] == "@"
        begin
          user_info = @users.select{|u| u.id == dest[1..-1]}[-1]
          msgs.each do |msg|
            send_msg_user(user_info.user.id, msg, on_thread)
            sleep wait
          end
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
    rescue Exception => stack
      @logger.warn stack
    end
  end

end
