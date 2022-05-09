class SlackSmartBot

  def get_repls(channel = @channel_id)
    require 'yaml'
    repl_file = "#{config.path}/repl/repls_#{channel}.yaml"

    if File.exist?("#{config.path}/repl/repls_#{channel}.rb") #backwards compatible
      file_conf = IO.readlines("#{config.path}/repl/repls_#{channel}.rb").join
      if file_conf.to_s() == ""
        @repls = {}
      else
        @repls = eval(file_conf)
      end
      File.open(repl_file, 'w') {|file| file.write(@repls.to_yaml) }
      File.delete("#{config.path}/repl/repls_#{channel}.rb")
    end

    if File.exist?(repl_file)      
      repls = @repls
      10.times do
        repls = YAML.load(File.read(repl_file))
        if repls.is_a?(Hash)
          break
        else
          sleep (0.1*(rand(2)+1))
        end
      end
      @repls = repls unless repls.is_a?(FalseClass)
    end
  end
end
