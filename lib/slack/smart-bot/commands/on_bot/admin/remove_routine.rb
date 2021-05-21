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
  # helpadmin:    <https://github.com/MarioRuiz/slack-smart-bot#routines|more info>
  # helpadmin:
  def remove_routine(dest, from, name)
    save_stats(__method__)
    if config.admins.include?(from) #admin user
      if !config.on_master_bot and dest[0] == "D"
        respond "To remove the routine do it on <##{@channel_id}>"
      elsif @routines.key?(@channel_id) and @routines[@channel_id].key?(name)
        @routines[@channel_id][name][:thread].exit
        @routines[@channel_id].delete(name)
        update_routines()
        respond "The routine *`#{name}`* has been removed.", dest
      else
        respond "There isn't a routine with that name: *`#{name}`*.\nCall `see routines` to see added routines", dest
      end
    else
      respond "Only admin users can delete routines", dest
    end
  end
end
