class SlackSmartBot

  # helpadmin: ----------------------------------------------
  # helpadmin: `kill routine NAME`
  # helpadmin: `delete routine NAME`
  # helpadmin: `remove routine NAME`
  # helpadmin:    It will kill and remove the specified routine
  # helpadmin:    You can use this command only if you are an admin user
  # helpadmin:    NAME: one word to identify the routine
  # helpadmin:    Examples:
  # helpadmin:      _kill routine example_
  # helpadmin:
  def remove_routine(dest, from, name)
    @logger.info "Start:#{Time.now}"
    if config.admins.include?(from) #admin user
      if !config.on_master_bot and dest[0] == "D"
        respond "It's only possible to remove routines from MASTER channel from a direct message with the bot.", dest
      elsif @routines.key?(@channel_id) and @routines[@channel_id].key?(name)
        @routines[@channel_id].delete(name)
        @logger.info "Cont:#{Time.now}"
        update_routines()
        @logger.info "end:#{Time.now}"
        respond "The routine *`#{name}`* has been removed.", dest
      else
        respond "There isn't a routine with that name: *`#{name}`*.\nCall `see routines` to see added routines", dest
      end
    else
      respond "Only admin users can delete routines", dest
    end
    @logger.info "fin:#{Time.now}"
  end
end
