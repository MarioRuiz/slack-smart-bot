class SlackSmartBot
  def get_teams
    @teams ||= {}
    teams_file = config.file_path.gsub(".rb", "_teams.yaml")
    if File.exist?(teams_file)
      if !defined?(@datetime_teams_file) or @datetime_teams_file != File.mtime(teams_file)
        require 'yaml'
        teams = @teams
        10.times do
          teams = YAML.load(File.read(teams_file))
          if teams.is_a?(Hash)
            break
          else
            sleep (0.1*(rand(2)+1))
          end
        end
        @teams = teams unless teams.is_a?(FalseClass)
        @datetime_teams_file = File.mtime(teams_file)
      end
    end
  end
end
