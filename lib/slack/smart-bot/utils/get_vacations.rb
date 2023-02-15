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
        File.write(File.join(config.path, "vacations", "v_#{key}.yaml"), encrypt(value.to_yaml))
      end
      @logger.info "Deleting old_vacations_file: #{old_vacations_file}"
      File.delete(old_vacations_file)
    end
    files = Dir.glob(File.join(config.path, "vacations", "v_*.yaml"))
    @datetime_vacations_file ||= {}
    files.each do |file|
      if !defined?(@datetime_vacations_file) or !@datetime_vacations_file.key?(file) or @datetime_vacations_file[file] != File.mtime(file)
        vacations_user = YAML.load(decrypt(File.read(file)))
        @vacations[File.basename(file).gsub("v_","").gsub(".yaml","")] = vacations_user
        @datetime_vacations_file[file] = File.mtime(file)
      end
    end
  end
end
