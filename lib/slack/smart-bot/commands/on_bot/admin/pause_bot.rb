class SlackSmartBot

  # helpadmin: ----------------------------------------------
  # helpadmin: `pause bot`
  # helpadmin: `pause this bot`
  # helpadmin:    the bot will pause so it will listen only to admin commands
  # helpadmin:    You can use this command only if you are an admin user
  # helpadmin:
  def pause_bot(dest, from)
    save_stats(__method__)
    if config.admins.include?(from) #admin user
      respond "This bot is paused from now on. You can start it again: start this bot", dest
      respond "zZzzzzZzzzzZZZZZZzzzzzzzz", dest
      @status = :paused
      @bots_created[@channel_id][:status] = :paused
      unless config.on_master_bot
        send_msg_channel config.master_channel, "Changed status on #{config.channel} to :paused"
      end
    else
      respond "Only admin users can put me on pause", dest
    end
  end
end
