class SlackSmartBot
  # list of available emojis: https://www.webfx.com/tools/emoji-cheat-sheet/
  # react(:thumbsup)
  def react(emoji, parent=false)
    if parent or Thread.current[:ts].to_s == ''
      ts = Thread.current[:thread_ts]
    else
      ts = Thread.current[:ts]
    end
    begin
      client.web_client.reactions_add(channel: Thread.current[:dest], name: emoji, timestamp: ts) unless settings.simulate
    rescue Exception => stack
      @logger.warn stack
    end
  end
end
