class SlackSmartBot

  def get_admins_channels()
    require 'yaml'
    admins_file = "#{config.path}/rules/#{@channel_id}/admins_channels.yaml"

    if File.exist?(admins_file.gsub(".yaml", ".rb")) #backwards compatible
      file_conf = IO.readlines(admins_file.gsub(".yaml", ".rb")).join
      if file_conf.to_s() == ""
        @admins_channels = {}
      else
        @admins_channels = eval(file_conf)
      end
      File.open(admins_file, 'w') {|file| file.write(@admins_channels.to_yaml) }
      File.delete(admins_file.gsub(".yaml", ".rb"))
    end

    if File.exist?(admins_file)      
      admins_channels = @admins_channels
      10.times do
        admins_channels = YAML.load(File.read(admins_file))
        if admins_channels.is_a?(Hash)
          break
        else
          sleep (0.1*(rand(2)+1))
        end
      end
      @admins_channels = admins_channels unless admins_channels.is_a?(FalseClass)
    else
      @admins_channels = {}
    end
  end
end
