class SlackSmartBot

  def update_routines(channel = @channel_id)

    require 'yaml'
    routines_file = "#{config.path}/routines/routines_#{channel}.yaml"

    routines = {}
    @routines.each do |k,v|
      routines[k]={}
      v.each do |kk,vv|
        routines[k][kk] = vv.dup
        routines[k][kk][:thread]=""
      end
    end
    File.open(routines_file, 'w') {|file|
      file.flock(File::LOCK_EX)
      file.write(routines.to_yaml) 
      file.flock(File::LOCK_UN)
    }
  end
end
