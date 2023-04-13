class SlackSmartBot
  def update_teams(team=nil)
    require 'yaml'
    if team.nil?
      teams = @teams.keys
    else
      get_teams()
      @teams.merge!(team)
      teams = team.keys      
    end

    teams.each do |team|
      team_file = File.join(config.path, "teams", "t_#{team}.yaml")
      File.open(team_file, 'w') {|file|
        file.flock(File::LOCK_EX)
        file.write(Utils::Encryption.encrypt(@teams[team].to_yaml, config))
        file.flock(File::LOCK_UN)
      }
      @datetime_teams_file[team_file] = File.mtime(team_file)
    end
  end
end