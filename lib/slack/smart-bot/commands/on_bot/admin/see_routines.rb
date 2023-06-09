class SlackSmartBot
  # helpadmin: ----------------------------------------------
  # helpadmin: `see routines`
  # helpadmin: `see routines HEADER /REGEXP/`
  # helpadmin: `see all routines`
  # helpadmin: `see all routines HEADER /REGEXP/`
  # helpadmin:    It will show the routines of the channel
  # helpadmin:    In case of 'all' and on the master channel, it will show all the routines from all channels
  # helpadmin:    If you use HEADER it will show only the routines that match the REGEXP on the header. Available headers: name, creator, status, next_run, last_run, command
  # helpadmin:    You can use this command only if you are an admin user
  # helpadmin:    <https://github.com/MarioRuiz/slack-smart-bot#routines|more info>
  # helpadmin: command_id: :see_routines
  # helpadmin:
  def see_routines(dest, from, user, all, header, regexp)
    save_stats(__method__)
    if is_admin?
      react :running
      if all
        routines = {}
        if config.on_master_bot
          Dir["#{config.path}/routines/routines_*.yaml"].each do |rout|
            routine = YAML.load(File.read(rout))
            unless routine.is_a?(FalseClass)
              routines.merge!(routine)
            end
          end
        else
          respond "To see all routines on all channels you need to run the command on the master channel.\nI'll display only the routines on this channel.", dest
          routines = @routines
        end
      else
        if @rules_imported.key?(user.name) and @rules_imported[user.name].key?(user.name) and dest[0] == "D"
          routines = YAML.load(File.read("#{config.path}/routines/routines_#{@rules_imported[user.name][user.name]}.yaml"))
          routines = {} if routines.is_a?(FalseClass)
        else
          routines = @routines
        end
      end

      if header != ''
        routines_filtered = {}

        routines.each do |ch, rout_ch|
          routines_filtered[ch] = rout_ch.dup
          rout_ch.each do |k, v|
            if header == 'name'
              if k.match(/#{regexp}/i).nil?
                routines_filtered[ch].delete(k)
              end
            elsif v[header.to_sym].to_s.match(/#{regexp}/i).nil?
              routines_filtered[ch].delete(k)
            end
          end
        end
        routines = routines_filtered
      end

      if routines.get_values(:channel_name).size == 0
        if header != ''
          respond "There are no routines added that match the header *#{header}* and the regexp *#{regexp}*.", dest
        else
          respond "There are no routines added.", dest
        end
      else
        routines.each do |ch, rout_ch|
          if header != ''
            respond "Routines on channel *#{rout_ch.get_values(:channel_name).values.flatten.uniq[0]}* that match the header *#{header}* and the regexp *#{regexp}*", dest
          else
            respond "Routines on channel *#{rout_ch.get_values(:channel_name).values.flatten.uniq[0]}*", dest
          end
          rout_ch.each do |k, v|
            msg = []
            if v[:dest][0] == 'D'
              extram = " (*DM to #{v[:creator]}*)"
            elsif v[:dest] != ch
              extram = " (*publish on <##{v[:dest]}>*)"
            else
              extram = ''
            end
            msg << "*`#{k}`*#{extram}"
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
            msg << "\tType: #{v[:routine_type]}" if v[:routine_type].to_s == 'bgroutine'
            respond msg.join("\n"), dest
          end
        end
      end
      unreact :running
    else
      respond "Only admin users can use this command", dest
    end
  end
end
