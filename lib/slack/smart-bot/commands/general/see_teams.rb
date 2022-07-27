class SlackSmartBot
  def see_teams(user, team_name, search = "", add_stats: true)
    save_stats(__method__) if add_stats

    get_teams()
    teams = @teams.deep_copy
    if teams.empty?
      respond "There are no teams added yet. Use `add team` command to add a team."
    elsif team_name.to_s != "" and !teams.key?(team_name.to_sym) and (teams.keys.select { |t| (t.to_s.gsub("-", "").gsub("_", "") == team_name.to_s) }).empty?
      respond "It seems like the team *#{team_name}* doesn't exist.\nRelated commands `add team TEAM_NAME PROPERTIES`, `see team TEAM_NAME`, `see teams`"
    else
      users_link = (Thread.current[:dest][0] == "D")
      filter = (search != "")
      react :runner
      @users = get_users() if add_stats

      messages = []
      search_members = []
      search_channels = []
      search_info = []
      if filter
        search.split(" ").each do |s|
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
      if team_name.to_s == "" and search.to_s == ""
        dest = :on_thread
        messages.unshift("Since there are many lines returned the results are returned on a thread by default.")
      else
        dest = Thread.current[:dest]
      end

      teams.each do |name, team|
        filter ? add = false : add = true
        if team_name.to_s == "" or (team_name.to_s == name.to_s) or (name.to_s.gsub("-", "").gsub("_", "") == team_name.to_s)
          message = []
          message << "*#{name.capitalize}*"

          if filter and search_info.size > 0
            all_info = true
            search_info.each do |s|
              if (team.members.keys.find { |e| /#{s}/i =~ e })
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
          channels_members = []
          all_team_members = assigned_members.dup
          if team.channels.key?("members")
            team_members = []
            team.channels["members"].each do |ch|
              get_channels_name_and_id() unless @channels_id.key?(ch)
              tm = get_channel_members(@channels_id[ch])
              if tm.nil?
                respond ":exclamation: Add the Smart Bot to *##{ch}* channel to be able to get the list of members.", dest
              else
                channels_members << @channels_id[ch]
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
            all_team_members += team_members
          else
            unassigned_members = []
            not_on_team_channel = []
          end
          unless unassigned_members.empty?
            um = unassigned_members.dup
            um.each do |m|
              user_info = @users.select { |u| u.name == m or (u.key?(:enterprise_user) and u.enterprise_user.name == m) }[-1]
              unless user_info.nil? or user_info.profile.title.to_s == ""
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
              if (team.members.keys.find { |e| /#{s}/i =~ e })
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
                        if (user_info.tz_offset - user.tz_offset).abs <= (4 * 3600)
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
                  unless status == ":exclamation:"
                    if users_link
                      message[-1] += "  #{status}<@#{member}>, "
                    else
                      user_info = @users.select { |u| u.name == member or (u.key?(:enterprise_user) and u.enterprise_user.name == member) }[-1]
                      unless user_info.nil?
                        if user_info.profile.display_name == ""
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
                      if user_info.profile.display_name == ""
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
                channel_info = @channels_list.select { |c| c.name.to_s.downcase == ch.to_s.downcase }[-1]
                if @channels_id.key?(ch) and (!channel_info.is_private or (channel_info.is_private and (team.members.values + [team.creator]).flatten.include?(user.name)))
                  channel_ids << @channels_id[ch]
                end
              end
              message << "        _`#{type}`_:  <##{channel_ids.join("> <#")}>" unless channel_ids.empty?
            end

            unless !team.key?(:memos) or team.memos.empty? or (team_name.to_s == "" and search.to_s == "")
              all_memos = {}
              team.memos.each do |memo|
                if memo.privacy.empty? or
                   (memo.privacy == "private" and (all_team_members.include?(user.name) and (users_link or channels_members.include?(Thread.current[:dest])))) or
                   (memo.privacy == "personal" and memo.user == user.name and users_link)
                  if memo.type == "jira" and config.jira.host != ""
                    http = NiceHttp.new(config.jira.host)
                    http.headers.authorization = NiceHttpUtils.basic_authentication(user: config.jira.user, password: config.jira.password)
                    if memo.message.match?(/^\w+\-\d+$/)
                      resp = http.get("/rest/api/latest/issue/#{memo.message}")
                      issues = [resp.data.json] if resp.code == 200
                    else
                      resp = http.get("/rest/api/latest/search/?jql=#{memo.message}")
                      issues = resp.data.json().issues if resp.code == 200
                    end
                    if resp.code == 200
                      unless issues.empty?
                        issues.each do |issue|
                          jira_memo = { jira: true, github: false, status: "", memo_id: memo.memo_id, topic: memo.topic, privacy: memo.privacy, user: memo.user, date: memo.date, message: "", type: memo.type }
                          jira_memo.message = issue.fields.summary
                          jira_memo.user = issue.fields.reporter.name
                          jira_memo.date = issue.fields.created
                          if memo.topic == :no_topic and !issue.fields.labels.empty?
                            jira_memo.topic = issue.fields.labels.sort.join("_").split(" ").join("_")
                          end
                          case issue.fields.issuetype.name
                          when "Story"; jira_memo.type = ":abc:"
                          when "Bug"; jira_memo.type = ":bug:"
                          when "Task"; jira_memo.type = ":clock1:"
                          when "New Feature", "Improvement"; jira_memo.type = ":sunny:"
                          else jira_memo.type = ":memo:"
                          end
                          case issue.fields.status.statusCategory.name
                          when "Done"; jira_memo.status = ":heavy_check_mark:"
                          when "To Do"; jira_memo.status = ":new:"
                          when "In Progress"; jira_memo.status = ":runner:"
                          else jira_memo.status = ":heavy_minus_sign:"
                          end
                          #todo: check if possible to add link to status instead of jira issue
                          #jira_memo.status = " <#{config.jira.host}/browse/#{issue[:key]}|#{jira_memo.status}> "
                          jira_memo.status += " <#{config.jira.host}/browse/#{issue[:key]}|#{issue[:key]}> "

                          all_memos[jira_memo.topic] ||= []
                          all_memos[jira_memo.topic] << jira_memo
                        end
                      end
                    end
                    http.close
                  elsif memo.type == "github" and config.github.host != ""
                    http = NiceHttp.new(config.github.host)
                    http.headers.authorization = "token #{config.github.token}"
                    memo.message+="?" unless memo.message.include?('?')
                    memo.message+="&per_page=50"
              
                    resp = http.get("/repos/#{memo.message}")
                    issues = resp.data.json()
                    issues = [issues] unless issues.is_a?(Array)
                    if resp.code == 200
                      unless issues.empty?
                        issues.each do |issue|
                          github_memo = { jira: false, github: true, status: "", memo_id: memo.memo_id, topic: memo.topic, privacy: memo.privacy, user: memo.user, date: memo.date, message: "", type: memo.type }
                          github_memo.message = issue.title
                          github_memo.user = issue.user.login
                          github_memo.date = issue.created_at
                          if issue.labels.empty?
                            labels = ''
                          else
                            labels = issue.labels.name.sort.join("_").split(" ").join("_") 
                          end
                          if memo.topic == :no_topic and !issue.labels.empty?
                            github_memo.topic = labels
                          end
                          case labels
                          when /bug/i; github_memo.type = ":bug:"
                          when /docum/i; github_memo.type = ":abc:"
                          when /task/i; github_memo.type = ":clock1:"
                          when /enhancem/i, /improvement/i; github_memo.type = ":sunny:"
                          else github_memo.type = ":memo:"
                          end
                          if issue.key?(:events_url)
                            resp_events = http.get(issue.events_url)
                            events = resp_events.data.json(:event)
                            issue.state = "in progress" if events.include?('referenced')
                          end
                          case issue.state
                          when "closed"; github_memo.status = ":heavy_check_mark:"
                          when "open"; github_memo.status = ":new:"
                          when "in progress"; github_memo.status = ":runner:"
                          else github_memo.status = ":heavy_minus_sign:"
                          end
                          #todo: check if possible to add link to status instead of github issue
                          github_memo.status += " <#{issue.html_url}|##{issue.number}> "

                          all_memos[github_memo.topic] ||= []
                          all_memos[github_memo.topic] << github_memo
                        end
                      end
                    end
                    http.close
                  else
                    memo.jira = false
                    memo.github = false
                    memo.status = ""
                    all_memos[memo.topic] ||= []
                    case memo.type
                    when "memo"; memo.type = ":memo:"
                    when "note"; memo.type = ":abc:"
                    when "bug"; memo.type = ":bug:"
                    when "task"; memo.type = ":clock1:"
                    when "feature"; memo.type = ":sunny:"
                    when "issue"; memo.type = ":hammer:"
                    else memo.type = ":heavy_minus_sign:"
                    end
                    all_memos[memo.topic] << memo
                  end
                end
              end
              message << "   > *_memos_*" unless all_memos.empty?

              if all_memos.key?(:no_topic)
                all_memos[:no_topic].sort_by { |memo| memo[:date] }.each do |memo|
                  case memo.privacy
                  when "private"; priv = " `private`"
                  when "personal"; priv = " `personal`"
                  else priv = ""
                  end
                  message << "        #{memo.type} #{memo.date.gsub("-", "/")[0..9]}:  #{memo.status}#{memo.message} (#{memo.user} #{memo.memo_id})#{priv}"
                end
              end
              all_memos[:no_topic] = []
              all_memos.each do |topic, mems|
                unless mems.empty?
                  message << "        _`#{topic}`_:"
                  mems.sort_by { |m| m[:date] }.each do |memo|
                    case memo.privacy
                    when "private"; priv = " `private`"
                    when "personal"; priv = " `personal`"
                    else priv = ""
                    end
                    message << "            #{memo.type} #{memo.date.gsub("-", "/")[0..9]}:  #{memo.status}#{memo.message} (#{memo.user} #{memo.memo_id})#{priv}"
                  end
                end
              end
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
