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
  # helpmaster:
  def set_maintenance(from, status, message)
    save_stats(__method__)
    if config.on_master_bot
      if config.admins.include?(from) #admin user
        if message == ''
          config.on_maintenance_message = "Sorry I'm on maintenance so I cannot attend your request."
        else
          config.on_maintenance_message = message
        end

        if status == 'on'
          config.on_maintenance = true
          respond "From now on I'll be on maintenance status so I won't be responding accordingly."
        else
          config.on_maintenance = false
          respond "From now on I won't be on maintenance. Everything is back to normal!"
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
