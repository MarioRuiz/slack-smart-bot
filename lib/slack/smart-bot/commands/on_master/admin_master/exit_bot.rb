class SlackSmartBot

  # helpadmin: ----------------------------------------------
  # helpadmin: `exit bot`
  # helpadmin: `quit bot`
  # helpadmin: `close bot`
  # helpadmin: `exit bot silent`
  # helpadmin:    The bot stops running and also stops all the bots created from this master channel
  # helpadmin:    You can use this command only if you are an admin user and you are on the master channel
  # helpadmin:    <https://github.com/MarioRuiz/slack-smart-bot#bot-management|more info>
  # helpadmin: command_id: :exit_bot
  # helpadmin:
  def exit_bot(command, user, dest, display_name, silent: false)
    save_stats(__method__)
    if config.on_master_bot
      if config.team_id_masters.include?("#{user.team_id}_#{user.name}") #master admin user
        if answer.empty?
          ask("are you sure?", command, user, dest)
        else
          case answer
          when /yes/i, /yep/i, /sure/i
            react :runner
            @bots_created.each { |key, value|
              value[:thread] = ""
              send_msg_channel(key, "Bot has been closed by #{user.name}") unless silent
              save_status :off, :exited, "The admin closed SmartBot on *##{value.channel_name}*"
              sleep 0.5
            }
            update_bots_file()
            sleep 0.5
            file = File.open("#{config.path}/config_tmp.status", "w")
            config.exit_bot = true
            @config_log.exit_bot = true
            file.write @config_log.inspect
            file.close
            @status = :exit
            respond "Game over!", dest
            @listening[:threads].each do |thread_ts, channel_thread|
              unreact :running, thread_ts, channel: channel_thread
              respond "ChatGPT session closed since SmartBot is going to be closed.\nCheck <##{@channels_id[config.status_channel]}>", channel_thread, thread_ts: thread_ts
            end
            if config.simulate
              sleep 2
              @status = :off
              config.simulate = false
              Thread.exit
            else
              respond "Ok, It will take around 40s to close all the bots, all routines and the master bot."
              sleep 35
              respond "Ciao #{display_name}!", dest
              unreact :runner
              react :beach_with_umbrella
              sleep 1
              exit!
            end
          when /no/i, /nope/i, /cancel/i
            answer_delete(user)
            respond "Thanks, I'm happy to be alive", dest
          else
            ask("I don't understand, are you sure do you want me to close? (yes or no)", command, user, dest)
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
