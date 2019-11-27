class SlackSmartBot
  def respond_direct(msg)
    dest = Thread.current[:user].id
    respond(msg, dest)
  end
end
