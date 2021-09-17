class SlackSmartBot
  # helpmaster: ----------------------------------------------
  # helpmaster: `publish announcements`
  # helpmaster:    It will publish on all channels the announcements added by using 'add announcement' command.
  # helpmaster:    Only works if you are on Master channel and you are a master admin user
  # helpmaster:    The messages stored on a DM won't be published.
  # helpmaster:    This is very convenient to be called from a *Routine* for example every weekday at 09:00.
  # helpmaster:    <https://github.com/MarioRuiz/slack-smart-bot#announcements|more info>
  # helpmaster:
  def publish_announcements(user)
    save_stats(__method__)
    if config.on_master_bot
      if config.admins.include?(user.name) #admin user
        channels = Dir.entries("#{config.path}/announcements/")
        channels.select! {|i| i[/\.csv$/]}
        channels.each do |channel|
          channel.gsub!('.csv','')
          unless channel[0]== 'D'
            see_announcements(user, '', channel, true, true)
            sleep 0.5 # to avoid reach ratelimit
          end
        end
        react :heavy_check_mark

      else
        respond 'Only master admins on master channel can use this command.'
      end
    else
      respond 'Only master admins on master channel can use this command.'
    end
  end
end
