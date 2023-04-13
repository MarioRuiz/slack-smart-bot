class SlackSmartBot
  def update_vacations(vacation=nil)
    require 'yaml'
    unless vacation.nil?
      get_vacations()
      @vacations.merge!(vacation)
    end
    user = Thread.current[:user]
    vacations_file = File.join(config.path, "vacations", "v_#{user.name}.yaml")

    File.open(vacations_file, 'w') {|file|
      file.flock(File::LOCK_EX)
      file.write(Utils::Encryption.encrypt(@vacations[user.name].to_yaml, config))
      file.flock(File::LOCK_UN)
    }
    @datetime_vacations_file[vacations_file] = File.mtime(vacations_file)
  end
end
