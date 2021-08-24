class SlackSmartBot
  def respond(msg = "", dest = nil, unfurl_links: true, unfurl_media: true, thread_ts: "", web_client: true, blocks: [], dont_share: false)
    result = true
    if (msg.to_s != "" or !msg.to_s.match?(/^A\s*\z/) or !blocks.empty?) and Thread.current[:routine_type].to_s != "bgroutine"
      if !web_client.is_a?(TrueClass) and !web_client.is_a?(FalseClass)
        (!unfurl_links or !unfurl_media) ? web_client = true : web_client = false
      end
      begin
        msg = msg.to_s
        web_client = true if !blocks.empty?

        on_thread = Thread.current[:on_thread]
        if dest.nil? and Thread.current.key?(:dest)
          dest = Thread.current[:dest]
        elsif dest.is_a?(Symbol) and dest == :on_thread
          on_thread = true
          dest = Thread.current[:dest]
        elsif dest.is_a?(Symbol) and dest == :direct
          dest = Thread.current[:user].id
        end
        if thread_ts.to_s.match?(/^\d+\.\d+$/)
          on_thread = true
          #thread id
        elsif thread_ts.to_s.match?(/^p\d\d\d\d\d+$/)
          on_thread = true
          #a thread id taken from url fex: p1622549264010700
          thread_ts = thread_ts.scan(/(\d+)/).join
          thread_ts = "#{thread_ts[0..9]}.#{thread_ts[10..-1]}"
        else
          thread_ts = Thread.current[:thread_ts] if thread_ts == ""
        end

        dest = @channels_id[dest] if @channels_id.key?(dest) #it is a name of channel

        if blocks.empty?
          if !config.simulate #https://api.slack.com/docs/rate-limits
            msg.size > 500 ? wait = 0.5 : wait = 0.1
            sleep wait if Time.now <= (@last_respond + wait)
          else
            wait = 0
          end

          msgs = [] # max of 4000 characters per message
          txt = ""
          msg.split("\n").each do |m|
            if (m + txt).size > 4000
              msgs << txt.chars.each_slice(4000).map(&:join) unless txt == ""
              txt = ""
            end
            txt += (m + "\n")
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
                  if web_client
                    resp = client.web_client.chat_postMessage(channel: @channel_id, text: msg, as_user: true, unfurl_links: unfurl_links, unfurl_media: unfurl_media, thread_ts: thread_ts)
                  else
                    resp = client.message(channel: @channel_id, text: msg, as_user: true, thread_ts: thread_ts, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
                  end
                  sleep wait
                end
              else
                msgs.each do |msg|
                  if web_client
                    resp = client.web_client.chat_postMessage(channel: @channel_id, text: msg, as_user: true, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
                  else
                    resp = client.message(channel: @channel_id, text: msg, as_user: true, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
                  end
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
                  if web_client
                    resp = client.web_client.chat_postMessage(channel: dest, text: msg, as_user: true, unfurl_links: unfurl_links, unfurl_media: unfurl_media, thread_ts: thread_ts)
                  else
                    resp = client.message(channel: dest, text: msg, as_user: true, thread_ts: thread_ts, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
                  end
                  sleep wait
                end
              else
                msgs.each do |msg|
                  if web_client
                    resp = client.web_client.chat_postMessage(channel: dest, text: msg, as_user: true, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
                  else
                    resp = client.message(channel: dest, text: msg, as_user: true, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
                  end
                  sleep wait
                end
              end
            end
            if config[:testing] and config.on_master_bot
              open("#{config.path}/buffer.log", "a") { |f|
                f.puts "|#{dest}|#{config[:nick_id]}|#{config[:nick]}|#{msg}"
              }
            end
          elsif dest[0] == "D" or dest[0] == "U" or dest[0] == "W" # Direct message
            msgs.each do |msg|
              send_msg_user(dest, msg, on_thread, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
              sleep wait
            end
          elsif dest[0] == "@"
            begin
              user_info = @users.select { |u| u.id == dest[1..-1] or (u.key?(:enterprise_user) and u.enterprise_user.id == dest[1..-1]) }[-1]
              msgs.each do |msg|
                send_msg_user(user_info.id, msg, on_thread, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
                sleep wait
              end
            rescue Exception => stack
              @logger.warn("user #{dest} not found.")
              @logger.warn stack
              if Thread.current.key?(:dest)
                respond("User #{dest} not found.")
              end
              result = false
            end
          else
            @logger.warn("method respond not treated correctly: msg:#{msg} dest:#{dest}")
            result = false
          end
        else
          wait = 0.1
          if dest.nil?
            if config[:simulate]
              open("#{config.path}/buffer_complete.log", "a") { |f|
                f.puts "|#{@channel_id}|#{config[:nick_id]}|#{config[:nick]}|#{blocks.join}~~~"
              }
            else
              if on_thread
                blocks.each_slice(40).to_a.each do |blockstmp|
                  resp = client.web_client.chat_postMessage(channel: @channel_id, blocks: blockstmp, as_user: true, thread_ts: thread_ts)
                  sleep wait
                end
              else
                blocks.each_slice(40).to_a.each do |blockstmp|
                  resp = client.web_client.chat_postMessage(channel: @channel_id, blocks: blockstmp, as_user: true)
                  sleep wait
                end
              end
            end
            if config[:testing] and config.on_master_bot
              open("#{config.path}/buffer.log", "a") { |f|
                f.puts "|#{@channel_id}|#{config[:nick_id]}|#{config[:nick]}|#{blocks.join}"
              }
            end
          elsif dest[0] == "C" or dest[0] == "G" # channel
            if config[:simulate]
              open("#{config.path}/buffer_complete.log", "a") { |f|
                f.puts "|#{dest}|#{config[:nick_id]}|#{config[:nick]}|#{blocks.join}~~~"
              }
            else
              if on_thread
                blocks.each_slice(40).to_a.each do |blockstmp|
                  resp = client.web_client.chat_postMessage(channel: dest, blocks: blockstmp, as_user: true, thread_ts: thread_ts)
                  sleep wait
                end
              else
                blocks.each_slice(40).to_a.each do |blockstmp|
                  resp = client.web_client.chat_postMessage(channel: dest, blocks: blockstmp, as_user: true)
                  sleep wait
                end
              end
            end
            if config[:testing] and config.on_master_bot
              open("#{config.path}/buffer.log", "a") { |f|
                f.puts "|#{dest}|#{config[:nick_id]}|#{config[:nick]}|#{blocks.join}"
              }
            end
          elsif dest[0] == "D" or dest[0] == "U" or dest[0] == "W" # Direct message
            blocks.each_slice(40).to_a.each do |blockstmp|
              send_msg_user(dest, msg, on_thread, unfurl_links: unfurl_links, unfurl_media: unfurl_media, blocks: blockstmp)
              sleep wait
            end
          elsif dest[0] == "@"
            begin
              user_info = @users.select { |u| u.id == dest[1..-1] or (u.key?(:enterprise_user) and u.enterprise_user.id == dest[1..-1]) }[-1]
              blocks.each_slice(40).to_a.each do |blockstmp|
                send_msg_user(user_info.id, msg, on_thread, unfurl_links: unfurl_links, unfurl_media: unfurl_media, blocks: blockstmp)
                sleep wait
              end
            rescue Exception => stack
              @logger.warn("user #{dest} not found.")
              @logger.warn stack
              if Thread.current.key?(:dest)
                respond("User #{dest} not found.")
              end
              result = false
            end
          else
            @logger.warn("method respond not treated correctly: msg:#{msg} dest:#{dest}")
            result = false
          end
        end
        @last_respond = Time.now
      rescue Exception => stack
        @logger.warn stack
        result = false
      end
    end
    if Thread.current.key?(:routine) and Thread.current[:routine]
      File.write("#{config.path}/routines/#{@channel_id}/#{Thread.current[:routine_name]}_output.txt", msg, mode: "a+")
    end
    return result
  end
end
