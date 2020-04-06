class SlackSmartBot

  # help: ----------------------------------------------
  # help: `use rules from CHANNEL`
  # help: `use rules CHANNEL`
  # help: `use CHANNEL`
  # help:    it will use the rules from the specified channel.
  # help:    you need to be part of that channel to be able to use the rules.
  # help:
  def use_rules(dest, channel, user, dchannel)
    save_stats(__method__)
    get_bots_created()
    if config[:allow_access].key?(__method__) and !config[:allow_access][__method__].include?(user.name) and !config[:allow_access][__method__].include?(user.id)
      respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
    else
      #todo: add pagination for case more than 1000 channels on the workspace
      channels = client.web_client.conversations_list(
        types: "private_channel,public_channel",
        limit: "1000",
        exclude_archived: "true",
      ).channels

      channel_found = channels.detect { |c| c.name == channel }
      members = client.web_client.conversations_members(channel: @channels_id[channel]).members unless channel_found.nil?

      if channel_found.nil?
        respond "The channel you are trying to use doesn't exist", dest
      elsif channel_found.name == config.master_channel
        respond "You cannot use the rules from Master Channel on any other channel.", dest
      elsif !@bots_created.key?(@channels_id[channel])
        respond "There is no bot running on that channel.", dest
      elsif @bots_created.key?(@channels_id[channel]) and @bots_created[@channels_id[channel]][:status] != :on
        respond "The bot in that channel is not :on", dest
      else
        if user.id == channel_found.creator or members.include?(user.id)
          @rules_imported[user.id] = {} unless @rules_imported.key?(user.id)
          if dest[0] == "C" or dest[0] == "G" #todo: take in consideration bots that are not master
            @rules_imported[user.id][dchannel] = channel_found.id
          else
            @rules_imported[user.id][user.id] = channel_found.id
          end
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
