class SlackSmartBot
  module Commands
    module General
      module Teams
        module Memos
          def see_memos_team(user, type: "all", name: nil, topic: "", add_stats: true, team: nil, memo_id: nil, precise: true)
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
                react :running unless !add_stats
                all_memos = {}
                assigned_members, unassigned_members, not_on_team_channel, channels_members, all_team_members = get_team_members(team)
                users_link = (Thread.current[:dest][0] == "D")
                memos_filtered = []
                all_topics = []
                num_issues = 0
                if memo_id.nil?
                  memo_selected = {}
                else
                  memo_selected = team[:memos].select { |m| m.memo_id == memo_id.to_i }[-1]
                end
                team[:memos].each do |memo|
                  if memo_id.nil? or memo[:memo_id] == memo_id.to_i
                    if topic == "" or (memo.topic == topic and precise) or (memo.topic.to_s.downcase.include?(topic.to_s.downcase) and !precise)
                      memos_filtered << memo
                      all_topics << memo.topic
                      if memo.key?(:search) and memo.key?(:issues) and memo.issues.size > 0
                        num_issues += memo.issues.size
                      else
                        num_issues += 1
                      end
                    end
                  end
                end
                all_topics.uniq!
                all_topics.delete(:no_topic)
                if num_issues >= 10 and !add_stats
                  message << "   > *_memos_*"
                  message << "        There are too many memos to show. "
                  message << "        Please use the `see MEMO_TYPE team #{team.name} TOPIC` command."
                  message << "        Some available topics: #{all_topics.join(", ")}" if all_topics.size > 0
                  message << "        Examples: `see bugs #{team.name} team`, `see all memos #{team.name} team #{all_topics.sample}`, `see tasks #{team.name} team #{all_topics.sample}`"
                elsif memos_filtered.size > 0
                  memos_filtered.each do |memo|
                    if memo.privacy.empty? or
                       (memo.privacy == "private" and (all_team_members.include?(user.name) and (users_link or channels_members.include?(Thread.current[:dest])))) or
                       (memo.privacy == "personal" and memo.user == user.name and users_link)
                      if memo.type == "jira" and config.jira.host != ""
                        http = NiceHttp.new(config.jira.host)
                        http.headers.authorization = NiceHttpUtils.basic_authentication(user: config.jira.user, password: config.jira.password)
                        if memo.message.match?(/^\w+\-\d+$/) or (memo.key?(:search) and !memo.search)
                          resp = http.get("/rest/api/latest/issue/#{memo.message}")
                          issues = [resp.data.json] if resp.code == 200
                          memo.search = false
                        else
                          resp = http.get("/rest/api/latest/search/?jql=#{memo.message}")
                          issues = resp.data.json().issues if resp.code == 200
                          memo.search = true
                        end
                        if resp.code == 200
                          unless issues.empty?
                            if memo.search
                              if memo.key?(:issues)
                                orig_issues = memo.issues.deep_copy.sort
                              else
                                orig_issues = []
                              end
                            end
                            memo_issues = []
                            issues.each do |issue|
                              jira_memo = { jira: true, github: false, status: "", memo_id: memo.memo_id, topic: memo.topic, privacy: memo.privacy, user: memo.user, date: memo.date, message: "", type: memo.type }
                              jira_memo.message = issue.fields.summary
                              memo_issues << jira_memo.message
                              jira_memo.user = issue.fields.reporter.name
                              jira_memo.date = issue.fields.created
                              jira_memo.search = memo.search
                              if issue.fields.key?(:comment) and issue.fields.comment.key?(:comments)
                                jira_memo.comments = issue.fields.comment.comments
                              elsif issue.fields.key?(:comments)
                                jira_memo.comments = issue.fields.comments
                              else
                                jira_memo.comments = []
                              end
                              if memo.topic == :no_topic and !issue.fields.labels.empty?
                                jira_memo.topic = issue.fields.labels.sort.join("_").split(" ").join("_")
                              end
                              if topic == "" or (topic != "" and jira_memo.topic.to_s.downcase == topic.to_s.downcase and precise) or
                                  (topic != "" and jira_memo.topic.to_s.downcase.include?(topic.to_s.downcase) and !precise)
                                case issue.fields.issuetype.name
                                when "Story"; jira_memo.type = ":abc:"; jira_memo.mtype = "memo"
                                when "Bug"; jira_memo.type = ":bug:"; jira_memo.mtype = "bug"
                                when "Task"; jira_memo.type = ":clock1:"; jira_memo.mtype = "task"
                                when "New Feature", "Improvement"; jira_memo.type = ":sunny:"; jira_memo.mtype = "feature"
                                else jira_memo.type = ":memo:"; jira_memo.mtype = "memo"
                                end

                                if (type == "all" or type.to_s == jira_memo.mtype.to_s or type == "")
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
                            if memo.search and orig_issues != memo_issues.sort
                              memo_selected = @teams[team.name.to_sym][:memos].select { |m| m.memo_id == memo.memo_id.to_i }[-1]
                              memo_selected[:issues] = memo_issues.deep_copy
                              memo_selected[:search] = true
                              update_teams()
                            end
                          end
                        end
                        http.close
                      elsif memo.type == "github" and config.github.host != ""
                        if memo.message.include?("?")
                          memo.search = true
                        else
                          memo.search = false
                        end

                        http = NiceHttp.new(config.github.host)
                        http.headers.authorization = "token #{config.github.token}"
                        issue_url = memo.message
                        issue_url + "?" unless issue_url.include?("?")
                        issue_url += "&per_page=50"

                        resp = http.get("/repos/#{issue_url}")
                        issues = resp.data.json()
                        issues = [issues] unless issues.is_a?(Array)
                        if resp.code == 200
                          unless issues.empty?
                            if memo.search
                              if memo.key?(:issues)
                                orig_issues = memo.issues.deep_copy.sort
                              else
                                orig_issues = []
                              end
                            end
                            memo_issues = []
                            issues.each do |issue|
                              github_memo = { jira: false, github: true, status: "", memo_id: memo.memo_id, topic: memo.topic, privacy: memo.privacy, user: memo.user, date: memo.date, message: "", type: memo.type }
                              github_memo.message = issue.title
                              memo_issues << github_memo.message
                              github_memo.user = issue.user.login
                              github_memo.date = issue.created_at
                              github_memo.search = memo.search
                              if issue.key?(:comments) and issue.comments.to_i > 0
                                github_memo.comments = [issue.comments.to_i]
                              else
                                github_memo.comments = []
                              end

                              if issue.labels.empty?
                                labels = ""
                              else
                                labels = issue.labels.name.sort.join("_").split(" ").join("_")
                              end
                              if memo.topic == :no_topic and !issue.labels.empty?
                                github_memo.topic = labels
                              end
                              if topic == "" or (topic != "" and github_memo.topic.to_s.downcase == topic.to_s.downcase and precise) or
                                  (topic != "" and github_memo.topic.to_s.downcase.include?(topic.to_s.downcase) and !precise)
                                case labels
                                when /bug/i; github_memo.type = ":bug:"; github_memo.mtype = "bug"
                                when /docum/i; github_memo.type = ":abc:"; github_memo.mtype = "note"
                                when /task/i; github_memo.type = ":clock1:"; github_memo.mtype = "task"
                                when /enhancem/i, /improvement/i; github_memo.type = ":sunny:"; github_memo.mtype = "feature"
                                else github_memo.type = ":memo:"; github_memo.mtype = "memo"
                                end

                                if (type == "all" or type.to_s == github_memo.mtype.to_s or type == "")
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
                            if memo.search and orig_issues != memo_issues.sort
                              memo_selected = @teams[team.name.to_sym][:memos].select { |m| m.memo_id == memo.memo_id.to_i }[-1]
                              memo_selected[:issues] = memo_issues.deep_copy
                              memo_selected[:search] = true
                              update_teams()
                            end
                          end
                        end
                        http.close
                      else
                        if topic == "" or (topic != "" and memo.topic.to_s.downcase == topic.to_s.downcase and precise) or
                            (topic != "" and memo.topic.to_s.downcase.include?(topic.to_s.downcase) and !precise)
                          if (type == "all" or type.to_s == memo[:type].to_s or type == "")
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
                    end
                  end
                  if all_memos.empty?
                    message << "There are no memos #{name} team #{type} #{topic}." unless !add_stats
                  else
                    if !add_stats
                      if memo_id.nil?
                        message << "   > *_memos_*"
                      else
                        if !memo_id.nil? and memo_selected and memo_selected.key?(:message) and
                           memo_selected.key?(:search) and memo_selected.search
                          message << "*_Team #{name.capitalize} memo #{memo_id}_*#{": #{memo_selected.message}"}"
                        else
                          message << "*_Team #{name.capitalize} memo #{memo_id}_*"
                        end
                      end
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
                        message << "        #{memo.type} #{memo.date.gsub("-", "/")[0..9]}:  #{memo.status} #{memo.message} (#{memo.user} #{memo.memo_id})#{priv}#{" :spiral_note_pad:" if memo.key?(:comments) and !memo.comments.empty?}#{" :mag:" if memo.key?(:search) and memo.search}"
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
                          message << "            #{memo.type} #{memo.date.gsub("-", "/")[0..9]}:  #{memo.status} #{memo.message} (#{memo.user} #{memo.memo_id})#{priv}#{" :spiral_note_pad:" if memo.key?(:comments) and !memo.comments.empty?}#{" :mag:" if memo.key?(:search) and memo.search}"
                        end
                      end
                    end
                  end
                else
                  message << "There are no memos #{name} team #{type} #{topic}." unless !add_stats
                end
                unreact :running unless !add_stats
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
      end
    end
  end
end
