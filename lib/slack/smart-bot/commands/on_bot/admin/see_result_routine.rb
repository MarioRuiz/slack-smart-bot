class SlackSmartBot

  # helpadmin: ----------------------------------------------
  # helpadmin: `see routine result NAME`
  # helpadmin: `see result routine NAME`
  # helpadmin: `result routine NAME`
  # helpadmin:    It will display the last result of the routine run.
  # helpadmin:    You can use this command only if you are an admin user
  # helpadmin:    NAME: one word to identify the routine
  # helpadmin:    Examples:
  # helpadmin:      _see routine result example_
  # helpadmin:    <https://github.com/MarioRuiz/slack-smart-bot#routines|more info>
  # helpadmin: command_id: :see_result_routine
  # helpadmin:
  def see_result_routine(dest, from, name)
    save_stats(__method__)
    if config.admins.include?(from) #admin user
      if @routines.key?(@channel_id) and @routines[@channel_id].key?(name)
        if File.exist?("#{config.path}/routines/#{@channel_id}/#{name}_output.txt")
          msg = "*Results from routine run #{File.mtime("#{config.path}/routines/#{@channel_id}/#{name}_output.txt")}*\n"
          msg += File.read("#{config.path}/routines/#{@channel_id}/#{name}_output.txt")
          respond msg, dest
        else
          respond "The routine *`#{name}`* doesn't have any result yet.", dest
        end
      else
        respond "There isn't a routine with that name: *`#{name}`*.\nCall `see routines` to see added routines", dest
      end
    else
      respond "Only admin users can see the routines results", dest
    end
  end
end
