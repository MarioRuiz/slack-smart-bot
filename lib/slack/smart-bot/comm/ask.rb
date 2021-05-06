class SlackSmartBot

  #context: previous message
  #to: user that should answer
  def ask(question, context = nil, to = nil, dest = nil)
    begin
      if dest.nil? and Thread.current.key?(:dest)
        dest = Thread.current[:dest]
      end
      if to.nil?
        to = Thread.current[:user].name
      end
      if context.nil?
        context = Thread.current[:command]
      end
      message = "#{to}: #{question}"
      if dest.nil?
        if config[:simulate]
          open("#{config.path}/buffer_complete.log", "a") { |f|
            f.puts "|#{@channel_id}|#{config[:nick_id]}|#{config[:nick]}|#{message}~~~"
          }
        else  
          if Thread.current[:on_thread]
            client.message(channel: @channel_id, text: message, as_user: true, thread_ts: Thread.current[:thread_ts])
          else
            client.message(channel: @channel_id, text: message, as_user: true)
          end
        end
        if config[:testing] and config.on_master_bot
          open("#{config.path}/buffer.log", "a") { |f|
            f.puts "|#{@channel_id}|#{config[:nick_id]}|#{config[:nick]}|#{message}"
          }
        end
      elsif dest[0] == "C" or dest[0] == "G" # channel
        if config[:simulate]
          open("#{config.path}/buffer_complete.log", "a") { |f|
            f.puts "|#{dest}|#{config[:nick_id]}|#{config[:nick]}|#{message}~~~"
          }
        else  
          if Thread.current[:on_thread]
            client.message(channel: dest, text: message, as_user: true, thread_ts: Thread.current[:thread_ts])
          else
            client.message(channel: dest, text: message, as_user: true)
          end
        end
        if config[:testing] and config.on_master_bot
          open("#{config.path}/buffer.log", "a") { |f|
            f.puts "|#{dest}|#{config[:nick_id]}|#{config[:nick]}|#{message}"
          }
        end
      elsif dest[0] == "D" #private message
        send_msg_user(dest, message)
      end
      if Thread.current[:on_thread]
        qdest = Thread.current[:thread_ts]
      else
        qdest = dest
      end
      @answer[to] = {} unless @answer.key?(to)
      @answer[to][qdest] = context
      @questions[to] = context # to be backwards compatible #todo remove it when 2.0
    rescue Exception => stack
      @logger.warn stack
    end
  end

end
