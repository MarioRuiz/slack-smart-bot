class SlackSmartBot

  def get_admins_channels()
    if File.exist?("#{config.path}/rules/#{@channel_id}/admins_channels.rb")
      file_conf = IO.readlines("#{config.path}/rules/#{@channel_id}/admins_channels.rb").join
      unless file_conf.to_s() == ""
        @admins_channels = eval(file_conf)
      end
    else
      @admins_channels = {}
    end
  end
end
