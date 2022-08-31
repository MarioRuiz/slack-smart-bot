class SlackSmartBot
  def update_vacations(vacation=nil)
    require 'yaml'
    unless vacation.nil?
      get_vacations()
      @vacations.merge!(vacation)
    end
    vacations_file = config.file_path.gsub(".rb", "_vacations.yaml")
    File.open(vacations_file, 'w') {|file|
      file.flock(File::LOCK_EX)
      file.write(@vacations.to_yaml) 
      file.flock(File::LOCK_UN)
    }
    @datetime_vacations_file = File.mtime(vacations_file)
  end
end
