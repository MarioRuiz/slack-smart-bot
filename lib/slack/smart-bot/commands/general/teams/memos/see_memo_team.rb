class SlackSmartBot
  module Commands
    module General
      module Teams
        module Memos
          def see_memo_team(user, team_name, memo_id)
            save_stats(__method__)
            get_teams()
            team_name = team_name.to_sym
            if @teams.key?(team_name)
              if @teams[team_name].key?(:memos)
                memo = @teams[team_name].memos.select { |m| m.memo_id == memo_id.to_i }[-1]
                memo_deleted = false
                deleted_memos_file = File.join(config.path, "teams", "t_#{team_name}_memos.yaml.deleted")
                if memo.nil? and File.exist?(deleted_memos_file)
                  mydata = File.read(deleted_memos_file)
                  all_deleted_memos = []
                  mydata.split(/^\s*$/).each do |memo|
                    all_deleted_memos << Utils::Encryption.decrypt(memo, config)
                  end
                  memos = YAML.load(all_deleted_memos.join("\n"))
                  memo = memos.select { |m| m.memo_id == memo_id.to_i }[-1]
                  memo_deleted = true if memo
                end
                if memo
                  if memo_deleted
                    uname = memo.user.split("_")[1..-1].join("_")
                    messages = ["This memo was deleted from the team #{team_name}.\nOnly the creator (#{uname}) of the memo can get access to it."]
                    if memo.user == "#{user.team_id}_#{user.name}"
                      messages << "Memo #{memo.memo_id} (#{memo.type}): #{memo.message}"
                    end
                  else
                    messages = see_memos_team(user, type: "all", add_stats: false, name: team_name, memo_id: memo_id)
                  end
                  if messages.empty?
                    messages = ["This memo is private or personal and you don't have access to it on this channel."]
                    messages << "Remember in case of a private memo you can only see it in the team members channel."
                    messages << "In case of a personal memo you can only see it if you are the creator and you are on a DM."
                    respond messages.join("\n")
                  else
                    if memo.type == "jira" and !memo_deleted
                      require "time"
                      if config.jira.host == "" or config.jira.user == "" or config.jira.password == ""
                        respond "You need to supply the correct credentials for JIRA on the SmartBot settings: `jira: { host: HOST, user: USER, password: PASSWORD }`"
                      else
                        begin
                          http = NiceHttp.new(config.jira.host)
                          http.headers.authorization = NiceHttpUtils.basic_authentication(user: config.jira.user, password: config.jira.password)
                          resp = http.get("/rest/api/2/issue/#{memo.message}/comment")
                          if resp.code.to_s == '200'
                            jira_comments = resp.data.json.comments
                            if !jira_comments.nil? and !jira_comments.empty?
                              messages << "\n_*JIRA Comments:*_"
                              jira_comments.each do |comment|
                                messages << "  *#{comment.author.displayName}* > #{comment.body} _(#{Time.parse(comment.created).strftime("%Y/%m/%d %H:%M")})_"
                              end
                            end
                          end
                          http.close
                        rescue => exception
                          @logger.fatal exception
                          respond "There was an error trying to connect to JIRA. Please ask the admin to check the logs."
                        end
                      end
                    elsif memo.type == "github" and !memo_deleted
                      http = NiceHttp.new(config.github.host)
                      http.headers.authorization = "token #{config.github.token}"
                      resp = http.get("/repos/#{memo.message}/comments")
                      if resp.code.to_s == '200'
                        github_comments = resp.data.json
                        if !github_comments.nil? and !github_comments.empty?
                          messages << "\n_*GitHub Comments:*_"
                          github_comments.each do |comment|
                            messages << "  *#{comment.user.login}* > #{comment.body} _(#{Time.parse(comment.created_at).strftime("%Y/%m/%d %H:%M")})_"
                          end
                        end
                      end
                      http.close
                    end
                    if memo.key?(:comments) and !memo.comments.empty? and (!memo_deleted or (memo_deleted and memo.user == "#{user.team_id}_#{user.name}"))
                      messages << "\n_*Comments:*_"
                      memo.comments.each do |comment|
                        uname = comment[:user_name].split("_")[1..-1].join("_")
                        messages << "  *#{uname}* > #{comment[:message]} _(#{comment[:time][0..15]})_"
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
      end
    end
  end
end
