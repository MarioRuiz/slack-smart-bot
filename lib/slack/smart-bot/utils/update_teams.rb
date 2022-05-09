class SlackSmartBot
  def update_teams(team=nil)
    require 'yaml'
    unless team.nil?
      get_teams()
      @teams.merge!(team)
    end
    teams_file = config.file_path.gsub(".rb", "_teams.yaml")
    File.open(teams_file, 'w') {|file|
      file.flock(File::LOCK_EX)
      file.write(@teams.to_yaml) 
      file.flock(File::LOCK_UN)
    }
    @datetime_teams_file = File.mtime(teams_file)
  end
end
