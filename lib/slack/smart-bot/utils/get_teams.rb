class SlackSmartBot
  def get_teams
    @teams ||= {}
    old_teams_file = config.file_path.gsub(".rb", "_teams.yaml") #to be backward compatible
    require 'yaml'
    if File.exist?(old_teams_file)
      @logger.info 'Migrating teams to new format'
      teams = YAML.load(File.read(old_teams_file))
      @logger.info "@teams: #{teams.inspect}}"
      teams.each do |key, value|
        File.write(File.join(config.path, "teams", "t_#{key}.yaml"), Utils::Encryption.encrypt(value.to_yaml, config))
      end
      @logger.info "Deleting old_teams_file: #{old_teams_file}"
      File.delete(old_teams_file)
    end
    files = Dir.glob(File.join(config.path, "teams", "t_*.yaml"))
    @datetime_teams_file ||= {}
    files.each do |file|
      if !defined?(@datetime_teams_file) or !@datetime_teams_file.key?(file) or @datetime_teams_file[file] != File.mtime(file)
        teams_team = YAML.load(Utils::Encryption.decrypt(File.read(file),config))
        team_name = File.basename(file).gsub("t_","").gsub(".yaml","")
        teams_team[:name] = team_name unless teams_team.key?(:name) #to be backward compatible
        @teams[team_name.to_sym] = teams_team
        @datetime_teams_file[file] = File.mtime(file)
      end
    end
    #remove from @teams and @datetime_teams_file the keys that are not in the files
    #this is to avoid having old data in memory
    @teams.keys.each do |key|
      unless files.include?(File.join(config.path, "teams", "t_#{key}.yaml"))
        @teams.delete(key)
        @datetime_teams_file.delete(File.join(config.path, "teams", "t_#{key}.yaml"))
      end
    end
  end
end
