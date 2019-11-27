class SlackSmartBot

  def update_routines(channel = @channel_id)
    routines = {}
    file = File.open("#{config.path}/routines/routines_#{channel}.rb", "w")
    @routines.each do |k,v|
      routines[k]={}
      v.each do |kk,vv|
        routines[k][kk] = vv.dup
        routines[k][kk][:thread]=""
      end
    end
    file.write (routines.inspect)
    file.close
  end
end
