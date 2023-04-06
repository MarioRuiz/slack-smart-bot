class SlackSmartBot
  def get_personal_settings
    @personal_settings ||= {}
    @datetime_personal_settings_file ||= {}
    files = Dir.glob(File.join(config.path, "personal_settings", "ps_*.yaml"))
    files.each do |file|
      if !defined?(@datetime_personal_settings_file) or !@datetime_personal_settings_file.key?(file) or @datetime_personal_settings_file[file] != File.mtime(file)
        user_personal_settings = YAML.load(decrypt(File.read(file)))
        @personal_settings[File.basename(file).gsub("ps_","").gsub(".yaml","")] = user_personal_settings
        @datetime_personal_settings_file[file] = File.mtime(file)
      end
    end
  end
end
