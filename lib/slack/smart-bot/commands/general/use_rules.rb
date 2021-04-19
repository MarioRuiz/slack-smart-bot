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
    if config[:allow_access].key?(__method__) and !config[:allow_access][__method__].include?(user.name) and !config[:allow_access][__method__].include?(user.id) and 
      (!user.key?(:enterprise_user) or ( user.key?(:enterprise_user) and !config[:allow_access][__method__].include?(user[:enterprise_user].id)))
      respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
    else
      #todo: add pagination for case more than 1000 channels on the workspace
      channels = get_channels()
      channel.gsub!('#','') # for the case the channel name is in plain text including #
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
