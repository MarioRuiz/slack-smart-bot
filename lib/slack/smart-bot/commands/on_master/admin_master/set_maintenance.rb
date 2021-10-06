class SlackSmartBot
  # helpmaster: ----------------------------------------------
  # helpmaster: `set maintenance on`
  # helpmaster: `set maintenance on MESSAGE`
  # helpmaster: `set maintenance off`
  # helpmaster: `turn maintenance on`
  # helpmaster: `turn maintenance on MESSAGE`
  # helpmaster: `turn maintenance off`
  # helpmaster:    The SmartBot will be on maintenance and responding with a generic message
  # helpmaster:    Only works if you are on Master channel and you are a master admin user
  # helpmaster:    You can add interpolation to the message you are adding
  # helpmaster:    Examples:
  # helpmaster:      _set maintenance on_
  # helpmaster:      _set maintenance on We are on maintenance. We'll be available again in #{((Time.new(2021,6,18,13,30,0)-Time.now)/60).to_i} minutes_
  # helpmaster:      _turn maintenance on `We are on *maintenance* until *12:00*`_
  # helpmaster:    <https://github.com/MarioRuiz/slack-smart-bot#bot-management|more info>
  # helpmaster:
  def set_maintenance(from, status, message)
    save_stats(__method__)
    if config.on_master_bot
      if config.masters.include?(from) #admin user
        if message == ''
          config.on_maintenance_message = "Sorry I'm on maintenance so I cannot attend your request."
        else
          config.on_maintenance_message = message
        end

        if status == 'on'
          config.on_maintenance = true
          respond "From now on I'll be on maintenance status so I won't be responding accordingly."
          save_status :off, :maintenance_on, config.on_maintenance_message
        else
          config.on_maintenance = false
          respond "From now on I won't be on maintenance. Everything is back to normal!"
          save_status :on, :maintenance_off, config.on_maintenance_message
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
