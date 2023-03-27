class SlackSmartBot
  def see_memo_team(user, team_name, memo_id)
    save_stats(__method__)
    get_teams()
    team_name = team_name.to_sym
    if @teams.key?(team_name)
      if @teams[team_name].key?(:memos)
        memo = @teams[team_name].memos.select { |m| m.memo_id == memo_id.to_i }[-1]
        if memo
          messages = see_memos_team(user, type: "all", add_stats: false, name: team_name, memo_id: memo_id)
          if messages.empty?
            messages = ["This memo is private or personal and you don't have access to it on this channel."]
            messages << "Remember in case of a private memo you can only see it in the team members channel."
            messages << "In case of a personal memo you can only see it if you are the creator and you are on a DM."
            respond messages.join("\n")
          else
            if memo.type == 'jira'
                require 'time'
                http = NiceHttp.new(config.jira.host)
                http.headers.authorization = NiceHttpUtils.basic_authentication(user: config.jira.user, password: config.jira.password)
                resp = http.get("/rest/api/2/issue/#{memo.message}/comment")
                if resp.code == 200
                    jira_comments = resp.data.json.comments
                    if !jira_comments.nil? and !jira_comments.empty?
                        messages << "\n_*JIRA Comments:*_"
                        jira_comments.each do |comment|
                            messages << "  *#{comment.author.displayName}* > #{comment.body} _(#{Time.parse(comment.created).strftime('%Y/%m/%d %H:%M')})_"
                        end
                    end
                end
                http.close
            elsif memo.type == 'github'
                http = NiceHttp.new(config.github.host)
                http.headers.authorization = "token #{config.github.token}"
                resp = http.get("/repos/#{memo.message}/comments")
                if resp.code == 200
                    github_comments = resp.data.json
                    if !github_comments.nil? and !github_comments.empty?
                        messages << "\n_*GitHub Comments:*_"
                        github_comments.each do |comment|
                            messages << "  *#{comment.user.login}* > #{comment.body} _(#{Time.parse(comment.created_at).strftime('%Y/%m/%d %H:%M')})_"
                        end
                    end
                end
                http.close
            end
            if memo.key?(:comments) and !memo.comments.empty?
                messages << "\n_*Comments:*_"
                memo.comments.each do |comment|
                    messages << "  *#{comment[:user_name]}* > #{comment[:message]} _(#{comment[:time][0..15]})_"
                end
            end

            if memo.key?(:comments) and memo.comments.size > 5
              respond_thread messages.join("\n")
            else
              respond messages.join("\n")
            end
          end
        else
          respond "Memo *#{memo_id}* does not exist in team *#{team_name}*."
        end
      else
        respond "There are no memos in team *#{team_name}*."
      end
    else
      respond "Team *#{team_name}* does not exist. Call `see teams` to see the list of teams."
    end
  end
end
