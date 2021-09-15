class SlackSmartBot
  # help: ----------------------------------------------
  # help: `stop using rules from CHANNEL`
  # help: `stop using CHANNEL`
  # help:    it will stop using the rules from the specified channel.
  # help:    <https://github.com/MarioRuiz/slack-smart-bot#using-rules-from-other-channels|more info>
  # help:
  def stop_using_rules(dest, channel, user, dchannel)
    save_stats(__method__)
    channel.gsub!('#','') # for the case the channel name is in plain text including #
    if @channels_id.key?(channel)
      channel_id = @channels_id[channel]
    else
      channel_id = channel
    end

    if dest[0] == "C" or dest[0] == "G" #channel
      if @rules_imported.key?(user.name) and @rules_imported[user.name].key?(dchannel)
        if @rules_imported[user.name][dchannel] != channel_id
          respond "You are not using those rules.", dest
        else
          @rules_imported[user.name].delete(dchannel)
          sleep 0.5
          update_rules_imported()
          respond "You won't be using those rules from now on.", dest

          def git_project() "" end
          def project_folder() "" end
        end
      else
        respond "You were not using those rules.", dest
      end
    else #direct message
      if @rules_imported.key?(user.name) and @rules_imported[user.name].key?(user.name)
        if @rules_imported[user.name][user.name] != channel_id
          respond "You are not using those rules.", dest
        else
          @rules_imported[user.name].delete(user.name)
          sleep 0.5
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
