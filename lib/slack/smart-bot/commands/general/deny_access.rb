class SlackSmartBot
  def deny_access(user, command_id)
    save_stats(__method__)
    not_allowed = ['hi_bot', 'bye_bot', "allow_access", "deny_access", "get_bot_logs", "add_routine", "pause_bot", "pause_routine", "remove_routine", "run_routine", "start_bot",
                   "start_routine", "delete_message", "update_message", "send_message", "kill_bot_on_channel", "exit_bot", "notify_message", "publish_announcements", "set_general_message",
                   "set_maintenance", 'bot_help', 'bot_rules']
    if !is_admin?(user.name)
      respond "Only admins of this channel can use this command. Take a look who is an admin of this channel by calling `see admins`"
    elsif Thread.current[:dest][0] == "D"
      respond "This command cannot be called from a DM"
    elsif not_allowed.include?(command_id)
      respond "Sorry but the access for `#{command_id}` cannot be changed."
    else
      if Thread.current[:typem] == :on_call
        channel = Thread.current[:dchannel]
      elsif Thread.current[:using_channel].to_s == ""
        channel = Thread.current[:dest]
      else
        channel = Thread.current[:using_channel]
      end
      command_ids = get_command_ids()
      if command_ids.values.flatten.include?(command_id)
        if !@access_channels.key?(channel)
          @access_channels[channel] = {}
        end

        @access_channels[channel][command_id] = []

        update_access_channels()
        respond "The command `#{command_id}` won't be available in this channel. Call `allow access #{command_id}` if you want it back."
      else
        respond "It seems like #{command_id} is not valid. Please be sure that exists by calling `see command ids`"
      end
    end
  end
end
