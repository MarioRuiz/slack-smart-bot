class SlackSmartBot
  def get_personal_settings()
    @personal_settings ||= {}
    @datetime_personal_settings_file ||= {}
    @personal_settings_hash ||= {}

    folders = Dir.glob(File.join(config.path, "personal_settings", "*")).select {|f| File.directory? f}
    files = []
    folders.each do |folder|
      files += Dir.glob(File.join(folder, "ps_*.yaml"))
    end

    files.each do |file|
      if !defined?(@datetime_personal_settings_file) or !@datetime_personal_settings_file.key?(file) or @datetime_personal_settings_file[file] != File.mtime(file)
        user_personal_settings = YAML.load(Utils::Encryption.decrypt(File.read(file),config))

        user_team_id = File.basename(File.dirname(file))
        user_file = user_team_id + "_" + File.basename(file).gsub("ps_","").gsub(".yaml","")

        @personal_settings[user_file] = user_personal_settings
        @datetime_personal_settings_file[file] = File.mtime(file)

        @personal_settings.each do |user, ps|
          @personal_settings_hash[user] = {}
          ps.each do |key, value|
            t = @personal_settings_hash[user]
            key.split('.').each_with_index do |k, i|
              if i == key.split('.').size - 1 #last element
                t[k.to_s.to_sym] = value
              else
                t[k.to_s.to_sym] ||= {}
                t = t[k.to_s.to_sym]
              end
            end
          end
        end
      end
    end
  end
end
