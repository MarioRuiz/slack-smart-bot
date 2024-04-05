class SlackSmartBot
  # helpmaster: ----------------------------------------------
  # helpmaster: `set general message MESSAGE`
  # helpmaster: `set general message off`
  # helpmaster:    The SmartBot will display the specified message after treating every command
  # helpmaster:    Only works if you are on Master channel and you are a master admin user
  # helpmaster:    You can add interpolation to the message you are adding
  # helpmaster:    Examples:
  # helpmaster:      _set general message We will be on maintenance at 12:00_
  # helpmaster:      _set general message We will be on maintenance in #{((Time.new(2021,6,18,13,30,0)-Time.now)/60).to_i} minutes_
  # helpmaster:      _set general message `We will be on *maintenance* at *12:00*`_
  # helpmaster:      _set general message `:information_source: Pay attention: We will be on *maintenance* in *#{((Time.new(2021,6,18,13,30,0)-Time.now)/60).to_i} minutes*`_
  # helpmaster:    <https://github.com/MarioRuiz/slack-smart-bot#bot-management|more info>
  # helpmaster: command_id: :set_general_message
  # helpmaster:
  def set_general_message(user, status, message)
    save_stats(__method__)
    if config.on_master_bot
      if config.team_id_masters.include?("#{user.team_id}_#{user.name}") #master admin user
        if status == 'on'
          config.general_message = message
          respond "General message has been set."
        else
          config.general_message = ''
          respond "General message won't be displayed anymore."
        end
        @config_log.general_message = config.general_message
        file = File.open("#{config.path}/config_tmp.status", "w")
        file.write @config_log.inspect
        file.close

      else
        respond 'Only master admins on master channel can use this command.'
      end
    else
      respond 'Only master admins on master channel can use this command.'
    end
  end
end
