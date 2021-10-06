class SlackSmartBot

  # help: ----------------------------------------------
  # help: `use rules from CHANNEL`
  # help: `use rules CHANNEL`
  # help: `use CHANNEL`
  # help:    it will use the rules from the specified channel.
  # help:    you need to be part of that channel to be able to use the rules.
  # help:    <https://github.com/MarioRuiz/slack-smart-bot#using-rules-from-other-channels|more info>
  # help:
  def use_rules(dest, channel, user, dchannel)
    save_stats(__method__)
    get_bots_created()
    if has_access?(__method__, user)
      #todo: add pagination for case more than 1000 channels on the workspace
      channels = get_channels()
      channel.gsub!('#','') # for the case the channel name is in plain text including #
      channel = @channels_name[channel] if @channels_name.key?(channel)
      channel_found = channels.detect { |c| c.name == channel }
      get_channels_name_and_id() unless @channels_id.key?(channel)
      members = get_channel_members(@channels_id[channel]) unless channel_found.nil? or !@channels_id.key?(channel)

      if channel_found.nil? or !@channels_id.key?(channel)
        respond "The channel you are trying to use doesn't exist or cannot be found.", dest
      elsif channel_found.name == config.master_channel
        respond "You cannot use the rules from Master Channel on any other channel.", dest
      elsif !@bots_created.key?(@channels_id[channel])
        respond "There is no bot running on that channel.", dest
      elsif @bots_created.key?(@channels_id[channel]) and @bots_created[@channels_id[channel]][:status] != :on
        respond "The bot in that channel is not :on", dest
      else
        if user.id == channel_found.creator or members.include?(user.id)
          @rules_imported[user.name] = {} unless @rules_imported.key?(user.name)
          if dest[0] == "C" or dest[0] == "G" #todo: take in consideration bots that are not master
            @rules_imported[user.name][dchannel] = channel_found.id
          else
            @rules_imported[user.name][user.name] = channel_found.id
          end
          sleep 0.5
          update_rules_imported()
          respond "I'm using now the rules from <##{channel_found.id}>", dest

          def git_project() "" end
          def project_folder() "" end
        else
          respond "You need to join the channel <##{channel_found.id}> to be able to use the rules.", dest
        end
      end
    end
  end
end
