class SlackSmartBot

  # helpadmin: ----------------------------------------------
  # helpadmin: `start bot`
  # helpadmin: `start this bot`
  # helpadmin:    the bot will start to listen
  # helpadmin:    You can use this command only if you are an admin user
  # helpadmin:
  def start_bot(dest, from)
    if ADMIN_USERS.include?(from) #admin user
      respond "This bot is running and listening from now on. You can pause again: pause this bot", dest
      @status = :on
      unless ON_MASTER_BOT
        send_msg_channel MASTER_CHANNEL, "Changed status on #{CHANNEL} to :on"
      end
    else
      respond "Only admin users can change my status", dest
    end
  end
end
