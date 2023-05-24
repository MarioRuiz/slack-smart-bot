class SlackSmartBot

  def update_rules_imported
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

    File.open("#{file_path}.yaml", 'w') {|file|
      file.flock(File::LOCK_EX)
      file.write(@rules_imported.to_yaml) 
      file.flock(File::LOCK_UN)
    }
  end
end
