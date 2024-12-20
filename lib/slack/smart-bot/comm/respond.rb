class SlackSmartBot
  def respond(msg = "", dest = nil, unfurl_links: true, unfurl_media: true, thread_ts: "", web_client: true, blocks: [], dont_share: false, return_message: false, max_chars_per_message: 4000, split: true)
    result = true
    resp = nil

    if Thread.current.key?(:prompt) and !Thread.current[:prompt].empty? #don't send response to slack since chatgpt will get the response from stdout
      Thread.current[:stdout] += "#{msg}\n"
      return true
    else
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

          on_thread ? txt_on_thread = ":on_thread:" : txt_on_thread = ""

          if blocks.empty?
            if !config.simulate #https://api.slack.com/docs/rate-limits
              msg.size > 500 ? wait = 0.5 : wait = 0.1
              sleep wait if Time.now <= (@last_respond + wait)
            else
              wait = 0
            end
            msgs = [] # max of max_chars_per_message characters per message
            if max_chars_per_message.nil?
              txt = msg
            else
              txt = ""
              in_a_code_block = false
              print_previous = false
              all_lines = msg.split("\n")

              all_lines.each_with_index do |m, i|
                if m.match?(/^\s*```/)
                  in_a_code_block = !in_a_code_block
                  num_chars_code = 0
                  print_previous = false
                  if in_a_code_block
                    all_lines[i + 1..-1].each do |l|
                      num_chars_code += l.size + 1 # +1 for the \n
                      break if l.match?(/^\s*```/)
                    end
                    if (num_chars_code + (m + txt).size > max_chars_per_message) and txt != ""
                      print_previous = true
                    end
                  end
                end
                if ((m + txt).size > max_chars_per_message and !in_a_code_block) or print_previous
                  unless txt == ""
                    txt[0] = "." if txt.match?(/\A\s\s\s/) #first line of message in slack don't show spaces at the begining so we force it by changing first char
                    if m.match?(/^\s*```\s*$/) and !in_a_code_block
                      txt += (m + "\n")
                      m = ""
                    end
                    if split
                      t = txt.chars.each_slice(max_chars_per_message).map(&:join) #jalsplit
                      msgs << t
                    else
                      msgs << txt #not necessary to split the message in smaller parts since we are sending it as a file now
                    end
                    txt = ""
                    print_previous = false if print_previous
                  end
                end
                txt += (m + "\n")
                txt[0] = "." if txt.match?(/\A\s\s\s/) #first line of message in slack don't show spaces at the begining so we force it by changing first char
                txt[0] = ".   " if txt.match?(/\A\t/)
              end
            end
            msgs << txt
            msgs.flatten!
            msgs.delete_if { |e| e.match?(/\A\s*\z/) }
            if dest.nil?
              if config[:simulate]
                open("#{config.path}/buffer_complete.log", "a") { |f|
                  f.puts "|#{@channel_id}|#{thread_ts}|#{config[:nick_id]}|#{config[:nick]}|#{txt_on_thread}#{msg}~~~"
                }
              else
                if on_thread
                  msgs.each do |msg|
                    if msg.size > max_chars_per_message
                      resp = send_file(@channel_id, "", "", "", "", "text", content: msg)
                    else
                      if web_client
                        resp = client.web_client.chat_postMessage(channel: @channel_id, text: msg, as_user: true, unfurl_links: unfurl_links, unfurl_media: unfurl_media, thread_ts: thread_ts)
                      else
                        resp = client.message(channel: @channel_id, text: msg, as_user: true, thread_ts: thread_ts, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
                      end
                    end
                    sleep wait
                  end
                else
                  msgs.each do |msg|
                    if msg.size > max_chars_per_message
                      resp = send_file(@channel_id, "", "", "", "", "text", content: msg)
                    else
                      if web_client
                        resp = client.web_client.chat_postMessage(channel: @channel_id, text: msg, as_user: true, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
                      else
                        resp = client.message(channel: @channel_id, text: msg, as_user: true, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
                      end
                    end
                    sleep wait
                  end
                end
              end
              if config[:testing] and config.on_master_bot and !@buffered
                @buffered = true
                open("#{config.path}/buffer.log", "a") { |f|
                  f.puts "|#{@channel_id}|#{thread_ts}|#{config[:nick_id]}|#{config[:nick]}|#{msg}"
                }
              end
            elsif dest[0] == "C" or dest[0] == "G" # channel
              if config[:simulate]
                open("#{config.path}/buffer_complete.log", "a") { |f|
                  f.puts "|#{dest}|#{thread_ts}|#{config[:nick_id]}|#{config[:nick]}|#{txt_on_thread}#{msg}~~~"
                }
              else
                if on_thread
                  msgs.each do |msg|
                    if msg.size > max_chars_per_message
                      resp = send_file(dest, "", "", "", "", "text", content: msg)
                    else
                      if web_client
                        resp = client.web_client.chat_postMessage(channel: dest, text: msg, as_user: true, unfurl_links: unfurl_links, unfurl_media: unfurl_media, thread_ts: thread_ts)
                      else
                        resp = client.message(channel: dest, text: msg, as_user: true, thread_ts: thread_ts, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
                      end
                    end
                    sleep wait
                  end
                else
                  msgs.each do |msg|
                    if msg.size > max_chars_per_message
                      resp = send_file(dest, "", "", "", "", "text", content: msg)
                    else
                      if web_client
                        resp = client.web_client.chat_postMessage(channel: dest, text: msg, as_user: true, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
                      else
                        resp = client.message(channel: dest, text: msg, as_user: true, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
                      end
                    end
                    sleep wait
                  end
                end
              end
              if config[:testing] and config.on_master_bot and !@buffered
                @buffered = true
                open("#{config.path}/buffer.log", "a") { |f|
                  f.puts "|#{dest}|#{thread_ts}|#{config[:nick_id]}|#{config[:nick]}|#{msg}"
                }
              end
            elsif dest[0] == "D" or dest[0] == "U" or dest[0] == "W" # Direct message
              msgs.each do |msg|
                if msg.size > max_chars_per_message
                  resp = send_file(dest, "", "", "", "", "text", content: msg)
                else
                  resp = send_msg_user(dest, msg, on_thread, unfurl_links: unfurl_links, unfurl_media: unfurl_media, thread_ts: thread_ts)
                end
                sleep wait
              end
            elsif dest[0] == "@"
              begin
                user_info = @users.select { |u| u.id == dest[1..-1] or u.name == dest[1..-1] or (u.key?(:enterprise_user) and u.enterprise_user.id == dest[1..-1]) }[-1]
                msgs.each do |msg|
                  if msg.size > max_chars_per_message
                    resp = send_file(user_info.id, "", "", "", "", "text", content: msg)
                  else
                    resp = send_msg_user(user_info.id, msg, on_thread, unfurl_links: unfurl_links, unfurl_media: unfurl_media, thread_ts: thread_ts)
                  end
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
                  f.puts "|#{@channel_id}|#{thread_ts}|#{config[:nick_id]}|#{config[:nick]}|#{txt_on_thread}#{blocks.join}~~~"
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
              if config[:testing] and config.on_master_bot and !@buffered
                @buffered = true
                open("#{config.path}/buffer.log", "a") { |f|
                  f.puts "|#{@channel_id}|#{thread_ts}|#{config[:nick_id]}|#{config[:nick]}|#{blocks.join}"
                }
              end
            elsif dest[0] == "C" or dest[0] == "G" # channel
              if config[:simulate]
                open("#{config.path}/buffer_complete.log", "a") { |f|
                  f.puts "|#{dest}|#{thread_ts}|#{config[:nick_id]}|#{config[:nick]}|#{txt_on_thread}#{blocks.join}~~~"
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
              if config[:testing] and config.on_master_bot and !@buffered
                @buffered = true
                open("#{config.path}/buffer.log", "a") { |f|
                  f.puts "|#{dest}|#{thread_ts}|#{config[:nick_id]}|#{config[:nick]}|#{blocks.join}"
                }
              end
            elsif dest[0] == "D" or dest[0] == "U" or dest[0] == "W" # Direct message
              blocks.each_slice(40).to_a.each do |blockstmp|
                resp = send_msg_user(dest, msg, on_thread, unfurl_links: unfurl_links, unfurl_media: unfurl_media, blocks: blockstmp, thread_ts: thread_ts)
                sleep wait
              end
            elsif dest[0] == "@"
              begin
                user_info = @users.select { |u| u.id == dest[1..-1] or (u.key?(:enterprise_user) and u.enterprise_user.id == dest[1..-1]) }[-1]
                blocks.each_slice(40).to_a.each do |blockstmp|
                  resp = send_msg_user(user_info.id, msg, on_thread, unfurl_links: unfurl_links, unfurl_media: unfurl_media, blocks: blockstmp, thread_ts: thread_ts)
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
      result = resp if return_message
      return result
    end
  end
end
