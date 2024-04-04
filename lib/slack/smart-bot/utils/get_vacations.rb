class SlackSmartBot
  def get_vacations
    @vacations ||= {}
    old_vacations_file = config.file_path.gsub(".rb", "_vacations.yaml") #to be backward compatible
    require 'yaml'
    if File.exist?(old_vacations_file)
      @logger.info 'Migrating vacations to new format'
      vacations = @vacations
      vacations = YAML.load(File.read(old_vacations_file))
      @vacations = vacations unless vacations.is_a?(FalseClass)
      @vacations.each do |key, value|
        File.write(File.join(config.path, "vacations", "v_#{key}.yaml"), Utils::Encryption.encrypt(value.to_yaml, config))
      end
      @logger.info "Deleting old_vacations_file: #{old_vacations_file}"
      File.delete(old_vacations_file)
    end
    # get the yaml files. They will be on /vacations then in there a folder for each team and inside the yaml files for each user
    folders = Dir.glob(File.join(config.path, "vacations", "*"))
    folders.each do |folder|
      if File.directory?(folder)
        files = Dir.glob(File.join(folder, "*.yaml"))
        @datetime_vacations_file ||= {}
        files.each do |file|
          if !defined?(@datetime_vacations_file) or !@datetime_vacations_file.key?(file) or @datetime_vacations_file[file] != File.mtime(file)
            vacations_user = YAML.load(Utils::Encryption.decrypt(File.read(file), config))
            #the key of @vacations will be the team_id_user_name
            team_id = File.basename(folder)
            @vacations["#{team_id}_#{File.basename(file).gsub("v_","").gsub(".yaml","")}"] = vacations_user
            @datetime_vacations_file[file] = File.mtime(file)
          end
        end
      end
    end
  end
end
