class SlackSmartBot

  # helpadmin: ----------------------------------------------
  # helpadmin: `extend rules to CHANNEL_NAME`
  # helpadmin: `use rules on CHANNEL_NAME`
  # helpadmin:    It will allow to use the specific rules from this channel on the CHANNEL_NAME
  # helpadmin:    <https://github.com/MarioRuiz/slack-smart-bot#extending-rules-to-other-channels|more info>
  # helpadmin:
  def extend_rules(dest, user, from, channel, typem)
    save_stats(__method__)
    unless typem == :on_extended
      if config.on_master_bot
        respond "You cannot use the rules from Master Channel on any other channel.", dest
      elsif !config.admins.include?(from) #not admin
        respond "Only admins can extend the rules. Admins on this channel: #{config.admins}", dest
      else
        #todo: add pagination for case more than 1000 channels on the workspace
        channels = get_channels()

        channel_found = channels.detect { |c| c.name == channel }
        get_channels_name_and_id()
        members = get_channel_members(@channels_id[channel]) unless channel_found.nil?
        get_bots_created()
        channels_in_use = []
        @bots_created.each do |k, v|
          if v.key?(:extended) and v[:extended].include?(channel)
            channels_in_use << v[:channel_name]
          end
        end
        if channel_found.nil?
          respond "The channel you specified doesn't exist or I don't have access to it. Be sure I was invited to that channel.", dest
        elsif @bots_created.key?(@channels_id[channel]) or channel == config.master_channel
          respond "There is a bot already running on that channel.", dest
        elsif @bots_created[@channel_id][:extended].include?(channel)
          respond "The rules are already extended to that channel.", dest
        elsif !members.include?(user.id)
          respond "You need to join that channel first", dest
        elsif !members.include?(config[:nick_id])
          respond "You need to add first to the channel the smart bot user: <@#{config[:nick_id]}>", dest
        else
          channels_in_use.each do |channel_in_use|
            respond "The rules from channel <##{@channels_id[channel_in_use]}> are already in use on that channel", dest
          end
          @bots_created[@channel_id][:extended] = [] unless @bots_created[@channel_id].key?(:extended)
          @bots_created[@channel_id][:extended] << channel
          update_bots_file()
          respond "<@#{user.id}> extended the rules from #{config.channel} to be used on #{channel}.", @master_bot_id
          if @channels_id[channel][0] == "G"
            respond "Now the rules from <##{@channel_id}> are available on *#{channel}*", dest
          else
            respond "Now the rules from <##{@channel_id}> are available on *<##{@channels_id[channel]}>*", dest
          end
          respond "<@#{user.id}> extended the rules from <##{@channel_id}> to this channel so now you can talk to the Smart Bot on demand using those rules.", @channels_id[channel]
          respond "Use `!` or `^` or `!!` before the command you want to run", @channels_id[channel]
          respond "To see the specific rules for this bot on this channel: `!bot rules` or `!bot rules COMMAND`", @channels_id[channel]
        end
      end
    end
  end
end
