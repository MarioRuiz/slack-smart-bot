class SlackSmartBot
  def update_personal_settings(user_personal_settings=nil)
    require 'yaml'
    unless user_personal_settings.nil?
      get_personal_settings()
      @personal_settings.merge!(user_personal_settings)
    end
    user = Thread.current[:user].dup
    team_id = user.team_id
    team_id_user = Thread.current[:team_id_user]

    unless Dir.exist?("#{config.path}/personal_settings/#{team_id}")
      Dir.mkdir("#{config.path}/personal_settings/#{team_id}")
    end

    personal_settings_file = File.join(config.path, "personal_settings/#{team_id}", "ps_#{user.name}.yaml")

    File.open(personal_settings_file, 'w') {|file|
      file.flock(File::LOCK_EX)
      file.write(Utils::Encryption.encrypt(@personal_settings[team_id_user].to_yaml, config))
      file.flock(File::LOCK_UN)
    }
    get_personal_settings() #to update the @personal_settings_hash
    @datetime_personal_settings_file[personal_settings_file] = File.mtime(personal_settings_file)
  end
end
