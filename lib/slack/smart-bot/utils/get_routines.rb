class SlackSmartBot

  def get_routines(channel = @channel_id)
    if File.exist?("#{config.path}/routines/routines_#{channel}.rb")
      file_conf = IO.readlines("#{config.path}/routines/routines_#{channel}.rb").join
      unless file_conf.to_s() == ""
        @routines = eval(file_conf)
      end
    end
  end
end
