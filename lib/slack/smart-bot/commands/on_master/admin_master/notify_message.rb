class SlackSmartBot
  # helpmaster: ----------------------------------------------
  # helpmaster: `notify MESSAGE`
  # helpmaster: `notify all MESSAGE`
  # helpmaster: `notify #CHANNEL_NAME MESSAGE`
  # helpmaster:    It will send a notification message to all bot channels
  # helpmaster:    It will send a notification message to all channels the bot joined and private conversations with the bot
  # helpmaster:    It will send a notification message to the specified channel and to its extended channels
  # helpmaster:    Only works if you are on Master channel and you are a master admin user
  # helpmaster:
  def notify_message(dest, from, where, message)
    save_stats(__method__)
    if config.on_master_bot
      if config.admins.include?(from) #admin user
        if where.nil? #not all and not channel
          @bots_created.each do |k, v|
            respond message, k
          end
          respond "Bot channels have been notified", dest
        elsif where == "all" #all
          myconv = client.web_client.users_conversations(exclude_archived: true, limit: 100, types: "im, public_channel,private_channel").channels
          myconv.each do |c|
            respond message, c.id unless c.name == config.master_channel
          end
          respond "Channels and users have been notified", dest
        else #channel
          respond message, where
          @bots_created[where][:extended].each do |ch|
            respond message, @channels_id[ch]
          end
          respond "Bot channel and extended channels have been notified", dest
        end
      end
    end
  end
end
