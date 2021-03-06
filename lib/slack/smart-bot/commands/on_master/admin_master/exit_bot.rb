class SlackSmartBot

  # helpadmin: ----------------------------------------------
  # helpadmin: `exit bot`
  # helpadmin: `quit bot`
  # helpadmin: `close bot`
  # helpadmin:    The bot stops running and also stops all the bots created from this master channel
  # helpadmin:    You can use this command only if you are an admin user and you are on the master channel
  # helpadmin:
  def exit_bot(command, from, dest, display_name)
    save_stats(__method__)
    if config.on_master_bot
      if config.admins.include?(from) #admin user
        unless @questions.keys.include?(from)
          ask("are you sure?", command, from, dest)
        else
          case @questions[from]
          when /yes/i, /yep/i, /sure/i
            respond "Game over!", dest
            respond "Ciao #{display_name}!", dest
            @bots_created.each { |key, value|
              value[:thread] = ""
              send_msg_channel(key, "Bot has been closed by #{from}")
              sleep 0.5
            }
            update_bots_file()
            sleep 0.5
            if config.simulate
              @status = :off
              config.simulate = false
              Thread.exit
            else
              exit!
            end
          when /no/i, /nope/i, /cancel/i
            @questions.delete(from)
            respond "Thanks, I'm happy to be alive", dest
          else
            ask("I don't understand, are you sure do you want me to close? (yes or no)", command, from, dest)
          end
        end
      else
        respond "Only admin users can kill me", dest
      end
    else
      respond "To do this you need to be an admin user in the master channel: <##{@master_bot_id}>", dest
    end
  end
end
