class SlackSmartBot

  def update_repls(channel = @channel_id)
    file = File.open("#{config.path}/repl/repls_#{channel}.rb", "w")
    file.write (@repls.inspect)
    file.close
  end
end
