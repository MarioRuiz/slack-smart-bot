class SlackSmartBot
  # helpadmin: ----------------------------------------------
  # helpadmin: `see routines`
  # helpadmin: `see all routines`
  # helpadmin:    It will show the routines of the channel
  # helpadmin:    In case of `all` and on the master channel, it will show all the routines from all channels
  # helpadmin:    You can use this command only if you are an admin user
  # helpadmin:
  def see_routines(dest, from, user, all)
    save_stats(__method__)
    if config.admins.include?(from) #admin user
      if all
        routines = {}
        if config.on_master_bot
          Dir["#{config.path}/routines/routines_*.rb"].each do |rout|
            file_conf = IO.readlines(rout).join
            unless file_conf.to_s() == ""
              routines.merge!(eval(file_conf))
            end
          end
        else
          respond "To see all routines on all channels you need to run the command on the master channel.\nI'll display only the routines on this channel.", dest
          routines = @routines.dup
        end
      else
        if @rules_imported.key?(user.id) and @rules_imported[user.id].key?(user.id) and dest[0] == "D"
          file_conf = IO.readlines("#{config.path}/routines/routines_#{@rules_imported[user.id][user.id]}.rb").join
          routines = eval(file_conf)
        else
          routines = @routines.dup
        end
      end

      if routines.get_values(:channel_name).size == 0
        respond "There are no routines added.", dest
      else
        routines.each do |ch, rout_ch|
          respond "Routines on channel *#{rout_ch.get_values(:channel_name).values.flatten.uniq[0]}*", dest
          rout_ch.each do |k, v|
            msg = []
            ch != v[:dest] ? directm = " (*DM to #{v[:creator]}*)" : directm = ""
            msg << "*`#{k}`*#{directm}"
            msg << "\tCreator: #{v[:creator]}"
            msg << "\tStatus: #{v[:status]}"
            msg << "\tEvery: #{v[:every]}" unless v[:every] == ""
            msg << "\tAt: #{v[:at]}" unless v[:at] == ""
            msg << "\tOn: #{v[:dayweek]}" unless !v.key?(:dayweek) or v[:dayweek].to_s == "" 
            msg << "\tNext Run: #{v[:next_run]}"
            msg << "\tLast Run: #{v[:last_run]}"
            msg << "\tTime consumed on last run: #{v[:last_elapsed]}" unless v[:command] !=''
            msg << "\tCommand: #{v[:command]}" unless v[:command].to_s.strip == ''
            msg << "\tFile: #{v[:file_path]}" unless v[:file_path] == ''
            msg << "\tSilent: #{v[:silent]}" unless !v[:silent]
            respond msg.join("\n"), dest
          end
        end
      end
    else
      respond "Only admin users can use this command", dest
    end
  end
end
