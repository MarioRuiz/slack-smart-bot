class SlackSmartBot
  def see_teams(user, team_name, search = "", add_stats: true)
    save_stats(__method__) if add_stats

    get_teams()
    teams = @teams.deep_copy
    if teams.empty?
      respond "There are no teams added yet. Use `add team` command to add a team."      
    elsif team_name.to_s != "" and !teams.key?(team_name.to_sym) and (teams.keys.select {|t| (t.to_s.gsub('-','').gsub('_','') == team_name.to_s)}).empty?
      respond "It seems like the team *#{team_name}* doesn't exist.\nRelated commands `add team TEAM_NAME PROPERTIES`, `see team TEAM_NAME`, `see teams`"
    else
      users_link = (Thread.current[:dest][0] == "D")
      filter = (search != '')
      react :runner
      @users = get_users() if add_stats

      messages = []
      search_members = []
      search_channels = []
      search_info = []
      if filter
        search.split(' ').each do |s|
          if s.match(/<@(\w+)>/i)
            m = $1
            user_info = @users.select { |u| u.id.downcase == m.downcase or (u.key?(:enterprise_user) and u.enterprise_user.id.downcase == m.downcase) }[-1]
            search_members << user_info.name unless user_info.nil?
          elsif s.match(/<#(\w+)\|[^>]*>/i)
            c = $1.upcase
            search_channels << @channels_name[c] if @channels_name.key?(c)
          else
            search_info << s
          end  
        end
      end
      if team_name.to_s == '' and search.to_s == ''
        dest = :on_thread
        messages.unshift('Since there are many lines returned the results are returned on a thread by default.')
      else
        dest = Thread.current[:dest]
      end

      teams.each do |name, team|
        filter ? add = false : add = true
        if team_name.to_s == "" or (team_name.to_s == name.to_s) or (name.to_s.gsub('-','').gsub('_','') == team_name.to_s)
          message = []
          message << "*#{name.capitalize}*"

          if filter and search_info.size > 0
            all_info = true
            search_info.each do |s|
              if (team.members.keys.find { |e| /#{s}/i =~ e})
                add = true 
                break              
              end
              if !name.match?(/#{s}/i)
                all_info = false
                break
              end
            end
            add = true if all_info
          end

          message << "   > *_members_*"

          assigned_members = team.members.values.flatten
          assigned_members.uniq!
          assigned_members.dup.each do |m|
            user_info = @users.select { |u| u.id == m or (u.key?(:enterprise_user) and u.enterprise_user.id == m) or u.name == m or (u.key?(:enterprise_user) and u.enterprise_user.name == m) }[-1]
            assigned_members.delete(m) if user_info.nil? or user_info.deleted
          end

          if team.channels.key?("members")
            team_members = []
            team.channels["members"].each do |ch|
              get_channels_name_and_id() unless @channels_id.key?(ch)
              tm = get_channel_members(@channels_id[ch])
              if tm.nil?
                respond ":exclamation: Add the Smart Bot to *##{ch}* channel to be able to get the list of members.", dest
              else
                tm.each do |m|
                  user_info = @users.select { |u| u.id == m or (u.key?(:enterprise_user) and u.enterprise_user.id == m) }[-1]
                  team_members << user_info.name unless user_info.is_app_user or user_info.is_bot
                end
              end
            end
            team_members.flatten!
            team_members.uniq!
            unassigned_members = team_members - assigned_members
            unassigned_members.delete(config.nick)
            not_on_team_channel = assigned_members - team_members
          else
            unassigned_members = []
            not_on_team_channel = []
          end
          unless unassigned_members.empty?
            um = unassigned_members.dup
            um.each do |m|
              user_info = @users.select { |u| u.name == m or (u.key?(:enterprise_user) and u.enterprise_user.name == m) }[-1]
              unless user_info.nil? or user_info.profile.title.to_s==''
                team.members[user_info.profile.title.to_snake_case] ||= []
                team.members[user_info.profile.title.to_snake_case] << m
                unassigned_members.delete(m)
              end
            end
            unless unassigned_members.empty?
              team.members["unassigned"] ||= []
              team.members["unassigned"] += unassigned_members
              team.members["unassigned"].sort!
            end
          end
          unless not_on_team_channel.empty?
            team.members["not on members channel"] = not_on_team_channel
            team.members["not on members channel"].sort!
          end
          add = true if (team.members.values.flatten & search_members).size > 0
          add = true if (team.channels.values.flatten & search_channels).size > 0
          if filter and search_info.size > 0
            all_info = true
            search_info.each do |s|
              if (team.members.keys.find { |e| /#{s}/i =~ e})
                add = true 
                break              
              end
              if !team.info.match?(/#{s}/i)
                all_info = false
                break
              end
            end
            add = true if all_info
          end

          if add
            if team_name.to_s != ""
              team.members.each do |type, members|
                message << "        _`#{type}`_:  "
                members.each do |member|
                  types = [":palm_tree:", ":spiral_calendar_pad:", ":face_with_thermometer:"]
                  member_info = @users.select { |u| u.name == member }[-1]
                  if !member_info.nil? and !member_info.deleted
                    member_id = member_info.id
                    info = get_user_info(member_id)
                    emoji = info.user.profile.status_emoji
                    if types.include?(emoji)
                      status = emoji
                    else
                      active = (get_presence(member_id).presence.to_s == "active")
                      if active
                        user_info = @users.select { |u| u.id == member_id or (u.key?(:enterprise_user) and u.enterprise_user.name == member_id) }[-1]
                        if (user_info.tz_offset-user.tz_offset).abs <= (4*3600)
                          status = ":large_green_circle:"
                        else
                          status = ":large_yellow_circle:"
                        end
                      else
                        status = ":white_circle:"
                      end
                    end
                  else
                    status = ":exclamation:"
                  end
                  unless status == ':exclamation:'
                    if users_link
                      message[-1] += "  #{status}<@#{member}>, "
                    else
                        user_info = @users.select { |u| u.name == member or (u.key?(:enterprise_user) and u.enterprise_user.name == member) }[-1]
                        unless user_info.nil?
                          if user_info.profile.display_name == ''
                            name = user_info.name
                          else
                            name = user_info.profile.display_name
                          end
                          message[-1] += "  #{status} #{name}, "
                        end
                    end
                  end
                end
                message[-1].chop!
                message[-1].chop!
              end
            else
              team.members.each do |type, members|
                if users_link
                  message << "        _`#{type}`_:  <@#{members.join(">,  <@")}>"
                else
                  membersn = []
                  members.each do |m|
                    user_info = @users.select { |u| u.name == m or (u.key?(:enterprise_user) and u.enterprise_user.name == m) }[-1]
                    unless user_info.nil? or user_info.deleted
                      if user_info.profile.display_name == ''
                        name = user_info.name
                      else
                        name = user_info.profile.display_name
                      end
                      membersn << name
                    end
                  end
                  message << "        _`#{type}`_:  #{membersn.join("  /  ")}"
                end
              end
            end
          end


          if add
            message << "   > *_channels_*"
            team.channels.each do |type, channels|
              channel_ids = []
              channels.each do |ch|
                channel_info = @channels_list.select { |c| c.name.to_s.downcase == ch.to_s.downcase}[-1]
                if @channels_id.key?(ch) and (!channel_info.is_private or (channel_info.is_private and (team.members.values+[team.creator]).flatten.include?(user.name)))
                  channel_ids << @channels_id[ch]
                end
              end
              message << "        _`#{type}`_:  <##{channel_ids.join("> <#")}>" unless channel_ids.empty?
            end

            unless team.info.empty?
              team.info.split("\n").each do |m|
                message << ">#{m}"
              end
              message << "> "
              message << "> "
            end
            messages << message.join("\n")
          end
        end
      end
      unreact :runner
      if messages.empty?
        if filter
          respond "It seems like we didn't find any team with the criteria supplied. Call `see teams` for a full list of teams."
        else
          respond "It seems like there are no teams added.\nUse `add team TEAM_NAME PROPERTIES` to add one. Call `bot help add team` for extended info."
        end
      else
        if team_name.to_s != ""
          message = "\n\n:palm_tree: On vacation / "
          message += ":spiral_calendar_pad: In a meeting / "
          message += ":face_with_thermometer: Sick leave / "
          message += ":white_circle: Away / "
          message += ":large_yellow_circle: Available in remote timezone / "
          message += ":large_green_circle: Available"
          messages[-1] << message
          messages[-1] << "\n:information_source: Remote Time zone is >4h away from your current (#{user.tz_label})"
        end
        messages.each do |msg|
          respond msg, dest, unfurl_links: false, unfurl_media: false
        end
      end
    end
  end
end