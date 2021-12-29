class SlackSmartBot

  def get_access_channels()
    if File.exist?("#{config.path}/rules/#{@channel_id}/access_channels.rb")
      file_conf = IO.readlines("#{config.path}/rules/#{@channel_id}/access_channels.rb").join
      unless file_conf.to_s() == ""
        @access_channels = eval(file_conf)
      end
    else
      @access_channels = {}
    end
  end
end
