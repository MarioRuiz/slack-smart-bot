class SlackSmartBot

  def get_repls(channel = @channel_id)
    if File.exist?("#{config.path}/repl/repls_#{channel}.rb")
      file_conf = IO.readlines("#{config.path}/repl/repls_#{channel}.rb").join
      unless file_conf.to_s() == ""
        @repls = eval(file_conf)
      end
    end
  end
end
