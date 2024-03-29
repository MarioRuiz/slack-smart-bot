# add here the general rules you will be using in all Smart Bots
def general_rules(user, command, processed, dest, files = [], rules_file = "")
    from = user.name
    display_name = user.profile.display_name
  
    begin
      case command

        # help: ----------------------------------------------
        # help: `echo SOMETHING`
        # help:     repeats SOMETHING
        # help:  Examples:
        # help:     _echo I am the Smart Bot_
        # help: command_id: :echo
      when /\A\s*echo\s(.+)\s*\z/im
            save_stats :echo
            respond $1

      else
        return false
      end
      return true
    rescue => exception
      if defined?(@logger)
        @logger.fatal exception
        respond "Unexpected error!! Please contact an admin to solve it: <@#{config.admins.join(">, <@")}>"
      else
        puts exception
      end
      return false
    end
end