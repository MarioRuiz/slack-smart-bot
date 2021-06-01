class SlackSmartBot
  # list of available emojis: https://www.webfx.com/tools/emoji-cheat-sheet/
  # react(:thumbsup)
  # ts: can be true, false or a specific ts
  def react(emoji, ts=false, channel='')
    channel = Thread.current[:dest] if channel == ''
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
    else
      if ts.to_s.match?(/^\d+\.\d+$/)
        #thread id
      elsif ts.to_s.match?(/^p\d\d\d\d\d+$/)
        #a thread id taken from url fex: p1622549264010700
        ts = ts.scan(/(\d+)/).join
        ts = "#{ts[0..9]}.#{ts[10..-1]}"
      else
        ts = Thread.current[:thread_ts] if ts == ''
      end

    end
    if ts.nil?
      @logger.warn 'react method no ts supplied'
    else
      emoji.gsub!(':','')
      begin
        client.web_client.reactions_add(channel: channel, name: emoji.to_sym, timestamp: ts) unless config.simulate
      rescue Exception => stack
        @logger.warn stack
      end
    end
  end
end
