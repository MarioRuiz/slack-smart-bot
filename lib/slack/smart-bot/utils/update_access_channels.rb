class SlackSmartBot

  def update_access_channels()
    require 'yaml'
    access_ch_file = "#{config.path}/rules/#{@channel_id}/access_channels"

    if File.exist?("#{access_ch_file}.rb") #backwards compatible
      file_conf = IO.readlines("#{access_ch_file}.rb").join
      if file_conf.to_s() == ""
        @access_channels = {}
      else
        @access_channels = eval(file_conf)
      end
      File.open("#{access_ch_file}.yaml", 'w') {|file| file.write(@access_channels.to_yaml) }
      File.delete("#{access_ch_file}.rb")
    end

    File.open("#{access_ch_file}.yaml", 'w') {|file|
      file.flock(File::LOCK_EX)
      file.write(@access_channels.to_yaml) 
      file.flock(File::LOCK_UN)
    }
  end
end
