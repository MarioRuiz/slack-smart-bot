class SlackSmartBot
  def allow_access(user, command_id, opt)
    save_stats(__method__)
    not_allowed = ["hi_bot", "bye_bot", "allow_access", "deny_access", "get_bot_logs", "add_routine", "pause_bot", "pause_routine", "remove_routine", "run_routine", "start_bot",
                   "start_routine", "delete_message", "send_message", "kill_bot_on_channel", "exit_bot", "notify_message", "publish_announcements", "set_general_message",
                   "set_maintenance", "bot_help", "bot_rules"]
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
        wrong_user = false
        access_users = []
        opt.each do |o|
          if o.match(/\A\s*<@([^>]+)>\s*\z/)
            access_users << $1
          else
            respond "Hmm, I've done some research on this and it looks like #{o} is not a valid Slack user.\nMake sure you are writing @USER and it is recognized by *Slack*\n"
            wrong_user = true
            break
          end
        end
        unless wrong_user
          if !@access_channels.key?(channel)
            @access_channels[channel] = {}
          end

          if access_users.empty? # all users will be able to access
            @access_channels[channel].delete(command_id)
          else
            if @access_channels.key?(channel) and !@access_channels[channel].key?(command_id)
              @access_channels[channel][command_id] = []
            end
            access_users_names = []
            access_users.each do |us|
              user_info = @users.select { |u| u.id == us or (u.key?(:enterprise_user) and u.enterprise_user.id == us) }[-1]
              access_users_names << user_info.name unless user_info.nil?
            end
            @access_channels[channel][command_id] += access_users_names
            @access_channels[channel][command_id].flatten!
            @access_channels[channel][command_id].uniq!
            @access_channels[channel][command_id].delete(nil)
          end
          update_access_channels()
          if !@access_channels[channel].key?(command_id)
            respond "All users will have access to this command on this channel."
          else
            respond "These users will have access to this command on this channel: <@#{@access_channels[channel][command_id].join(">, <@")}>"
          end
        end
      else
        respond "It seems like #{command_id} is not valid. Please be sure that exists by calling `see command ids`"
      end
    end
  end
end
