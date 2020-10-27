class SlackSmartBot
  # list of available emojis: https://www.webfx.com/tools/emoji-cheat-sheet/
  # unreact(:thumbsup)
  def unreact(emoji, parent=false)
    if parent
      ts = Thread.current[:thread_ts]
    else
      ts = Thread.current[:ts]
    end
    begin
      client.web_client.reactions_remove(channel: Thread.current[:dest], name: emoji, timestamp: ts) unless config.simulate
    rescue Exception => stack
      @logger.warn stack
    end
  end
end
