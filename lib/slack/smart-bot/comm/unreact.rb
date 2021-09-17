class SlackSmartBot
  # list of available emojis: https://www.webfx.com/tools/emoji-cheat-sheet/
  # unreact(:thumbsup)
  # ts: can be true, false or a specific ts
  def unreact(emoji, ts=false)
    begin
      if ts.is_a?(TrueClass) or ts.is_a?(FalseClass)
        parent = ts
        ts = nil
      else
        parent = false
      end
      if ts.nil?
        if parent or Thread.current[:ts].to_s == ''
          ts = Thread.current[:thread_ts]
        else
          ts = Thread.current[:ts]
        end
      end
      if ts.nil?
        @logger.warn 'unreact method no ts supplied'
      else
        begin
          client.web_client.reactions_remove(channel: Thread.current[:dest], name: emoji, timestamp: ts) unless config.simulate
        rescue Exception => stack
          @logger.warn stack
        end
      end
    rescue Exception => stack
      @logger.warn stack
    end
  end
end
