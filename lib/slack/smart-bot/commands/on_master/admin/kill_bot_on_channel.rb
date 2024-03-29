class SlackSmartBot
  # helpmaster: ----------------------------------------------
  # helpmaster: `kill bot on CHANNEL_NAME`
  # helpmaster:    kills the bot on the specified channel
  # helpmaster:    Only works if you are on Master channel and you created that bot or you are an admin user
  # helpmaster:    <https://github.com/MarioRuiz/slack-smart-bot#bot-management|more info>
  # helpmaster: command_id: :kill_bot_on_channel
  # helpmaster:
  def kill_bot_on_channel(dest, from, channel)
    save_stats(__method__)
    if config.on_master_bot
      get_channels_name_and_id() unless @channels_name.keys.include?(channel) or @channels_id.keys.include?(channel)
      channel_id = nil
      if @channels_name.key?(channel) #it is an id
        channel_id = channel
        channel = @channels_name[channel_id]
      elsif @channels_id.key?(channel) #it is a channel name
        channel_id = @channels_id[channel]
      end
      if channel_id.nil?
        respond "There is no channel with that name: #{channel}, please be sure is written exactly the same", dest
      elsif @bots_created.keys.include?(channel_id)
        @bots_created[channel_id] ||= {}
        if @bots_created[channel_id][:admins].to_s.split(",").include?(from) # todo: consider adding is_admin?
          if @bots_created[channel_id][:thread].kind_of?(Thread) and @bots_created[channel_id][:thread].alive?
            @bots_created[channel_id][:thread].kill
          end
          @bots_created.delete(channel_id)
          send_msg_channel(channel, "Bot has been killed by #{from}")
          respond "Bot on channel: #{channel}, has been killed and deleted.", dest
          save_status :off, :killed, "The admin killed SmartBot on *##{@channels_name[channel_id]}*"
          update_bots_file()
        else
          respond "You need to be the creator or an admin of that bot channel", dest
        end
      else
        respond "There is no bot in this channel: #{channel}", dest
      end
    else
      respond "Sorry I cannot kill bots from this channel, please visit the master channel: <##{@master_bot_id}>", dest
    end
  end
end
