class SlackSmartBot

  # helpadmin: ----------------------------------------------
  # helpadmin: `start bot`
  # helpadmin: `start this bot`
  # helpadmin:    the bot will start to listen
  # helpadmin:    You can use this command only if you are an admin user
  # helpadmin:    <https://github.com/MarioRuiz/slack-smart-bot#bot-management|more info>
  # helpadmin: command_id: :start_bot
  # helpadmin:
  def start_bot(dest, from)
    save_stats(__method__)
    if is_admin?
      respond "This bot is running and listening from now on. You can pause again: pause this bot", dest
      @status = :on
      unless config.on_master_bot
        @bots_created[@channel_id][:status] = :on
        update_bots_file()
        send_msg_channel config.master_channel, "Changed status on #{config.channel} to :on"
      end
      save_status :on, :started, 'The admin started this bot'
    else
      respond "Only admin users can change my status", dest
    end
  end
end
