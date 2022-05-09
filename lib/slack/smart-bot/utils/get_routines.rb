class SlackSmartBot

  def get_routines(channel = @channel_id)
    require 'yaml'
    routines_file = "#{config.path}/routines/routines_#{channel}.yaml"

    if File.exist?("#{config.path}/routines/routines_#{channel}.rb") #backwards compatible
      file_conf = IO.readlines("#{config.path}/routines/routines_#{channel}.rb").join
      if file_conf.to_s() == ""
        @routines = {}
      else
        @routines = eval(file_conf)
      end
      File.open(routines_file, 'w') {|file| file.write(@routines.to_yaml) }
      File.delete("#{config.path}/routines/routines_#{channel}.rb")
    end

    if File.exist?(routines_file)      
      routines = @routines
      10.times do
        routines = YAML.load(File.read(routines_file))
        if routines.is_a?(Hash)
          break
        else
          sleep (0.1*(rand(2)+1))
        end
      end
      @routines = routines unless routines.is_a?(FalseClass)
    end
  end
end
