class SlackSmartBot
  def get_vacations
    @vacations ||= {}
    vacations_file = config.file_path.gsub(".rb", "_vacations.yaml")
    if File.exist?(vacations_file)
      if !defined?(@datetime_vacations_file) or @datetime_vacations_file != File.mtime(vacations_file)
        require 'yaml'
        vacations = @vacations
        10.times do
          vacations = YAML.load(File.read(vacations_file))
          if vacations.is_a?(Hash)
            break
          else
            sleep (0.1*(rand(2)+1))
          end
        end
        @vacations = vacations unless vacations.is_a?(FalseClass)
        @datetime_vacations_file = File.mtime(vacations_file)
      end
    end
  end
end
