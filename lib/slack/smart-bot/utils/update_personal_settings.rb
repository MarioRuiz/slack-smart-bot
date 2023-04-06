class SlackSmartBot
  def update_personal_settings(user_personal_settings=nil)
    require 'yaml'
    unless user_personal_settings.nil?
      get_personal_settings()
      @personal_settings.merge!(user_personal_settings)
    end
    user = Thread.current[:user]
    personal_settings_file = File.join(config.path, "personal_settings", "ps_#{user.name}.yaml")

    File.open(personal_settings_file, 'w') {|file|
      file.flock(File::LOCK_EX)
      file.write(encrypt(@personal_settings[user.name].to_yaml))
      file.flock(File::LOCK_UN)
    }
    @datetime_personal_settings_file[personal_settings_file] = File.mtime(personal_settings_file)
  end
end
