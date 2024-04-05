class SlackSmartBot

  def get_access_channels()
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

    if File.exist?("#{access_ch_file}.yaml")      
      access_channels = @access_channels
      10.times do
        access_channels = YAML.load(File.read("#{access_ch_file}.yaml"))
        if access_channels.is_a?(Hash)
          break
        else
          sleep (0.1*(rand(2)+1))
        end
      end
      @access_channels = access_channels unless access_channels.is_a?(FalseClass)
    else
      @access_channels = {}
    end
  end
end
