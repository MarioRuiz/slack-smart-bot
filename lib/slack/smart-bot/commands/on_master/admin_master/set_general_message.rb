class SlackSmartBot
  # helpmaster: ----------------------------------------------
  # helpmaster: `set general message MESSAGE`
  # helpmaster: `set general message off`
  # helpmaster: `turn maintenance off`
  # helpmaster:    The SmartBot will display the specified message after treating every command
  # helpmaster:    Only works if you are on Master channel and you are a master admin user
  # helpmaster:    <https://github.com/MarioRuiz/slack-smart-bot#bot-management|more info>
  # helpmaster:
  def set_general_message(from, status, message)
    save_stats(__method__)
    if config.on_master_bot
      if config.admins.include?(from) #admin user
        if status == 'on'
          config.general_message = message
          respond "General message has been set."
        else
          config.general_message = ''
          respond "General message won't be displayed anymore."
        end
        
        file = File.open("#{config.path}/config_tmp.status", "w")
        file.write config.inspect
        file.close
    
      else
        respond 'Only master admins on master channel can use this command.'
      end
    else
      respond 'Only master admins on master channel can use this command.'
    end
  end
end
