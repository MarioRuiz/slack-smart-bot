class SlackSmartBot

  # helpadmin: ----------------------------------------------
  # helpadmin: `start routine NAME`
  # helpadmin:    It will start a paused routine
  # helpadmin:    You can use this command only if you are an admin user
  # helpadmin:    NAME: one word to identify the routine
  # helpadmin:    Examples:
  # helpadmin:      _start routine example_
  # helpadmin:

  def start_routine(dest, from, name)
    if ADMIN_USERS.include?(from) #admin user
      if !ON_MASTER_BOT and dest[0] == "D"
        respond "It's only possible to start routines from MASTER channel from a direct message with the bot.", dest
      elsif @routines.key?(@channel_id) and @routines[@channel_id].key?(name)
        @routines[@channel_id][name][:status] = :on
        update_routines()
        respond "The routine *`#{name}`* has been started. The change will take effect in less than 30 secs.", dest
      else
        respond "There isn't a routine with that name: *`#{name}`*.\nCall `see routines` to see added routines", dest
      end
    else
      respond "Only admin users can use this command", dest
    end
  end
end
