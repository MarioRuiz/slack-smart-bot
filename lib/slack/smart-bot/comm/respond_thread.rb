class SlackSmartBot
  def respond_thread(msg)
    respond(msg, Thread.current[:thread_ts])
  end
end
