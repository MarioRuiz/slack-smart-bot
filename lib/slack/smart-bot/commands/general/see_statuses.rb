class SlackSmartBot
  def see_statuses(user, channel, types, dest, not_on)
    save_stats(__method__)
    react :runner
    if channel == ""
      if dest[0] == "D"
        cdest = @channel_id
      else
        cdest = dest
      end
    else
      get_channels_name_and_id() unless @channels_name.keys.include?(channel) or @channels_id.keys.include?(channel)
      channel_id = nil
      if @channels_name.key?(channel) #it is an id
        channel_id = channel
        channel = @channels_name[channel_id]
      elsif @channels_id.key?(channel) #it is a channel name
        channel_id = @channels_id[channel]
      end
      cdest = channel_id
    end
    members = get_channel_members(cdest)
    if members.include?(user.id)
      list = {}
      only_active = false
      if types == ['available']
        only_active = true
        not_on = true
        types = [':palm_tree:', ':spiral_calendar_pad:', ':face_with_thermometer:']
      end
      members.each do |member|
        info = get_user_info(member)
        text = info.user.profile.status_text
        emoji = info.user.profile.status_emoji
        exp = info.user.profile.expiration
        unless (((!types.empty? and !types.include?(emoji)) or (emoji.to_s == "" and text.to_s == "" and exp.to_s == "")) and !not_on) or
               (not_on and types.include?(emoji)) or info.user.deleted or info.user.is_bot or info.user.is_app_user
          if only_active
            active = (get_presence(member).presence.to_s == 'active')
          else
            active = false
          end
          if !only_active or (only_active and active)
            emoji = ":white_square:" if emoji.to_s == ""
            list[emoji] ||= []
            list[emoji] << {
              type: "context",
              elements: [
                {
                            type: "plain_text",
                            text: "\t\t",
                          },
                {
                            type: "image",
                            image_url: info.user.profile.image_24,
                            alt_text: info.user.name,
                          },
                {
                            type: "mrkdwn",
                            text: " *#{info.user.profile.real_name}* (#{info.user.name}) #{text} #{exp}",
                          },
              ],
            }
          end
        end
      end
      if list.size > 0
        list.each do |emoji, users|
          emoji = '' if only_active
          blocks = [
            {
                      "type": "context",
                      elements: [
                        {
                            type: "mrkdwn",
                            text: "#{'*Available* ' if only_active}*Members* #{emoji} on <##{cdest}>",
                          },
                      ],
                    },
          ]
          users = users.sort_by { |hsh| hsh.elements[2].text }
          respond blocks: (blocks+users)
        end
      else
        respond "Nobody on <##{cdest}> with that status"
      end
    else
      respond "You need to join <##{cdest}> to be able to see the statuses on that channel."
    end
    unreact :runner
  end
end
