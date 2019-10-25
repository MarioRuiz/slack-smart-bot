class SlackSmartBot
  # helpadmin: ----------------------------------------------
  # helpadmin: `pause routine NAME`
  # helpadmin:    It will pause the specified routine
  # helpadmin:    You can use this command only if you are an admin user
  # helpadmin:    NAME: one word to identify the routine
  # helpadmin:    Examples:
  # helpadmin:      _pause routine example_
  # helpadmin:
  def pause_routine(dest, from, name)
    if config.admins.include?(from) #admin user
      if !config.on_master_bot and dest[0] == "D"
        respond "It's only possible to pause routines from MASTER channel from a direct message with the bot.", dest
      elsif @routines.key?(@channel_id) and @routines[@channel_id].key?(name)
        @routines[@channel_id][name][:status] = :paused
        @routines[@channel_id][name][:next_run] = ""
        update_routines()
        respond "The routine *`#{name}`* has been paused.", dest
      else
        respond "There isn't a routine with that name: *`#{name}`*.\nCall `see routines` to see added routines", dest
      end
    else
      respond "Only admin users can use this command", dest
    end
  end
end
