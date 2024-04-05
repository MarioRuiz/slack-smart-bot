class SlackSmartBot

  def get_rules_imported
    require 'yaml'
    file_path = "#{config.path}/rules/rules_imported"
    if File.exist?("#{file_path}.rb") #backwards compatible
      file_conf = IO.readlines("#{file_path}.rb").join
      if file_conf.to_s() == ""
        @rules_imported = {}
      else
        @rules_imported = eval(file_conf)
      end
      File.open("#{file_path}.yaml", 'w') {|file| file.write(@rules_imported.to_yaml) }
      File.delete("#{file_path}.rb")
    end

    if File.exist?("#{file_path}.yaml")      
      if !defined?(@datetime_rules_imported) or @datetime_rules_imported != File.mtime("#{file_path}.yaml")        
        @datetime_rules_imported = File.mtime("#{file_path}.yaml")
        rules_imported = @rules_imported
        10.times do
          rules_imported = YAML.load(File.read("#{file_path}.yaml"))
          if rules_imported.is_a?(Hash)
            break
          else
            sleep (0.1*(rand(2)+1))
          end
        end
        @rules_imported = rules_imported unless rules_imported.is_a?(FalseClass)
      end
    else
      @rules_imported = {}
    end
  end
  
end
