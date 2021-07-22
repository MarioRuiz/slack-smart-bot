# add here the general rules you will be using in all Smart Bots
def general_rules(user, command, processed, dest, files = [], rules_file = "")
    from = user.name
    display_name = user.profile.display_name
  
    begin
      case command

        # help: ----------------------------------------------
        # help: `echo SOMETHING`
        # help: `INTEGER echo SOMETHING`
        # help:     repeats SOMETHING. If INTEGER supplied then that number of times.
        # help:  Examples:
        # help:     _echo I am the Smart Bot_
        # help:     _100 echo :heart:_
      when /\A\s*(\d*)\s*echo\s(.+)/i
        save_stats :echo
        $1.to_s == '' ? times = 1 : times = $1.to_i
        respond ($2*times).to_s

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