class SlackSmartBot
  def update_vacations(vacation=nil)
    require 'yaml'
    unless vacation.nil?
      get_vacations()
      @vacations.merge!(vacation)
    end
    user = Thread.current[:user]
    team_id_user = Thread.current[:team_id_user]
    #create folder if doesn't exist
    FileUtils.mkdir_p(File.join(config.path, "vacations/#{user.team_id}")) unless File.exist?(File.join(config.path, "vacations/#{user.team_id}"))
    vacations_file = File.join(config.path, "vacations/#{user.team_id}", "v_#{user.name}.yaml")

    File.open(vacations_file, 'w') {|file|
      file.flock(File::LOCK_EX)
      file.write(Utils::Encryption.encrypt(@vacations[team_id_user].to_yaml, config))
      file.flock(File::LOCK_UN)
    }
    @datetime_vacations_file[vacations_file] = File.mtime(vacations_file)
  end
end
