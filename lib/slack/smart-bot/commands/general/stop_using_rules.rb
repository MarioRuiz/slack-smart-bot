class SlackSmartBot
  # help: ----------------------------------------------
  # help: `stop using rules from CHANNEL`
  # help:    it will stop using the rules from the specified channel.
  # help:
  def stop_using_rules(dest, channel, user, dchannel)
    save_stats(__method__)
    if @channels_id.key?(channel)
      channel_id = @channels_id[channel]
    else
      channel_id = channel
    end

    if dest[0] == "C" or dest[0] == "G" #channel
      if @rules_imported.key?(user.id) and @rules_imported[user.id].key?(dchannel)
        if @rules_imported[user.id][dchannel] != channel_id
          respond "You are not using those rules.", dest
        else
          @rules_imported[user.id].delete(dchannel)
          update_rules_imported()
          respond "You won't be using those rules from now on.", dest

          def git_project() "" end
          def project_folder() "" end
        end
      else
        respond "You were not using those rules.", dest
      end
    else #direct message
      if @rules_imported.key?(user.id) and @rules_imported[user.id].key?(user.id)
        if @rules_imported[user.id][user.id] != channel_id
          respond "You are not using those rules.", dest
        else
          @rules_imported[user.id].delete(user.id)
          update_rules_imported()
          respond "You won't be using those rules from now on.", dest

          def git_project() "" end
          def project_folder() "" end
        end
      else
        respond "You were not using those rules.", dest
      end
    end
  end
end
