class SlackSmartBot
  def see_memos_team(user, type: "all", name: nil, topic: "", add_stats: true, team: nil)
    save_stats(__method__) if add_stats

    get_teams()
    type = "all" if type.match?(/all\s+memo/i)
    message = []
    if @teams.size > 0
      if team.nil?
        @teams.each do |team_name, teamv|
          if (team_name.to_s == name.to_s) or (name.to_s.gsub("-", "").gsub("_", "") == team_name.to_s)
            if teamv.key?(:memos) and teamv[:memos].size > 0
              team = teamv.deep_copy
            else
              respond "There are no memos for the team #{name}." unless !add_stats
            end
            break
          end
        end
      end
      if team
        all_memos = {}
        assigned_members, unassigned_members, not_on_team_channel, channels_members, all_team_members = get_team_members(team)
        users_link = (Thread.current[:dest][0] == "D")
        memos_filtered = []
        all_topics = []
        team[:memos].each do |memo|
          if (type == "all" or type.to_s == memo[:type].to_s or type == "") and (topic == "" or memo[:topic].to_s.downcase == topic.to_s.downcase)
            memos_filtered << memo
            all_topics << memo.topic
          end
        end
        all_topics.uniq!
        all_topics.delete(:no_topic)
        if memos_filtered.size >= 10 and !add_stats
          message << "   > *_memos_*"
          message << "        There are too many memos to show. "
          message << "        Please use the `see MEMO_TYPE team #{team.name} TOPIC` command."
          message << "        Available topics: #{all_topics.join(", ")}" if all_topics.size > 0
          message << "        Examples: `see bugs #{team.name} team`, `see all memos #{team.name} team #{all_topics.sample}`, `see tasks #{team.name} team #{all_topics.sample}`"
        elsif memos_filtered.size > 0
          memos_filtered.each do |memo|
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
                      jira_memo.status += " <#{config.jira.host}/browse/#{issue[:key]}|#{issue[:key]}>"

                      all_memos[jira_memo.topic] ||= []
                      all_memos[jira_memo.topic] << jira_memo
                    end
                  end
                end
                http.close
              elsif memo.type == "github" and config.github.host != ""
                http = NiceHttp.new(config.github.host)
                http.headers.authorization = "token #{config.github.token}"
                memo.message += "?" unless memo.message.include?("?")
                memo.message += "&per_page=50"

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
                        labels = ""
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
                        issue.state = "in progress" if events.include?("referenced")
                      end
                      case issue.state
                      when "closed"; github_memo.status = ":heavy_check_mark:"
                      when "open"; github_memo.status = ":new:"
                      when "in progress"; github_memo.status = ":runner:"
                      else github_memo.status = ":heavy_minus_sign:"
                      end
                      #todo: check if possible to add link to status instead of github issue
                      github_memo.status += " <#{issue.html_url}|##{issue.number}>"

                      all_memos[github_memo.topic] ||= []
                      all_memos[github_memo.topic] << github_memo
                    end
                  end
                end
                http.close
              else
                memo.jira = false
                memo.github = false
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
          if !add_stats
            message << "   > *_memos_*" unless all_memos.empty?
          else
            message << "  > *_#{team.name} team #{type}_*"
          end

          if all_memos.key?(:no_topic)
            all_memos[:no_topic].sort_by { |memo| memo[:date] }.each do |memo|
              case memo.privacy
              when "private"; priv = " `private`"
              when "personal"; priv = " `personal`"
              else priv = ""
              end
              message << "        #{memo.type} #{memo.date.gsub("-", "/")[0..9]}:  #{memo.status} #{memo.message} (#{memo.user} #{memo.memo_id})#{priv}"
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
                message << "            #{memo.type} #{memo.date.gsub("-", "/")[0..9]}:  #{memo.status} #{memo.message} (#{memo.user} #{memo.memo_id})#{priv}"
              end
            end
          end
        else
          message << "There are no memos #{type} #{topic}." unless !add_stats
        end
      else
        respond "There is no team named #{name}." unless !add_stats
      end
      if add_stats
        respond message.join("\n")
      else
        return message
      end
    else
      respond "There are no teams added yet\. Use `add team` command to add a team" unless !add_stats
    end
  end
end
