class SlackSmartBot
  module Commands
    module General
      module Teams
        module Memos
          def add_memo_team(user, privacy, team_name, topic, type, message)
            save_stats(__method__)

            get_teams()
            if @teams.key?(team_name.to_sym)
              assigned_members = @teams[team_name.to_sym].members.values.flatten
              assigned_members.uniq!
              all_team_members = assigned_members.dup
              team_members = []
              if @teams[team_name.to_sym].channels.key?("members")
                @teams[team_name.to_sym].channels["members"].each do |ch|
                  get_channels_name_and_id() unless @channels_id.key?(ch)
                  tm = get_channel_members(@channels_id[ch])
                  tm.each do |m|
                    user_info = find_user(m)
                    team_members << "#{user_info.team_id}_#{user_info.name}" unless user_info.is_app_user or user_info.is_bot
                  end
                end
              end
              team_members.flatten!
              team_members.uniq!
              all_team_members += team_members
              all_team_members.uniq!
            end
            search = false
            if type == "jira"
              able_to_connect_jira = false
              begin
                if config.jira.host == "" or config.jira.user == "" or config.jira.password == ""
                  respond "You need to supply the correct credentials for JIRA on the SmartBot settings: `jira: { host: HOST, user: USER, password: PASSWORD }`"
                else
                  http = NiceHttp.new(config.jira.host)
                  http.headers.authorization = NiceHttpUtils.basic_authentication(user: config.jira.user, password: config.jira.password)
                  message.gsub!(/^\s*</, "")
                  message.gsub!(/\>$/, "")
                  message.gsub!(/\|.+$/, "")
                  message.gsub!(/^#{config.jira.host}/, "")
                  if message.include?("/browse/")
                    message = message.scan(/\/browse\/(.+)/).join
                    resp = http.get("/rest/api/latest/issue/#{message}")
                  else
                    message.gsub!(/^\/issues\/\?jql=/, "")
                    message.gsub!(" ", "%20")
                    resp = http.get("/rest/api/latest/search/?jql=#{message}")
                    search = true
                  end
                  if resp.code.to_s == '200'
                    able_to_connect_jira = true
                  else
                    error_code = resp.code.to_s
                    if resp.code.to_s == '400'
                      error_message = resp.data.json(:errorMessages)[-1]
                    else
                      error_message = ""
                    end
                  end
                  http.close
                end
              rescue => exception
                @logger.fatal exception
                respond "There was an error trying to connect to JIRA. Please ask the admin to check the logs."
              end
            elsif type == "github"
              able_to_connect_github = false
              begin
                search = true if message.include?("?")
                http = NiceHttp.new(config.github.host)
                http.headers.authorization = "token #{config.github.token}"
                message.gsub!(/^\s*</, "")
                message.gsub!(/\>$/, "")
                message.gsub!(/\|.+$/, "")
                message.gsub!(/^#{config.github.host}/, "")
                message.gsub!("https://github.com", "")
                message.slice!(0) if message[0] == "/"
                resp = http.get("/repos/#{message}")
                if resp.code.to_s == '200'
                  able_to_connect_github = true
                else
                  error_code = resp.code.to_s
                  if resp.code.to_s == '401'
                    error_message = resp.data.json(:message)[-1]
                  else
                    error_message = ""
                  end
                end
                http.close
              rescue => exception
                @logger.fatal exception
              end
            end

            if !@teams.key?(team_name.to_sym)
              respond "It seems like the team *#{team_name}* doesn't exist\nRelated commands `add team TEAM_NAME PROPERTIES`, `see team TEAM_NAME`, `see teams`"
            elsif !(all_team_members + config.team_id_masters).flatten.include?("#{user.team_id}_#{user.name}")
              respond "You have to be a member of the team or a Master admin to be able to add a memo to the team."
            elsif type == "jira" and !able_to_connect_jira
              if error_message == ""
                respond "You need to supply the correct credentials for JIRA on the SmartBot settings: `jira: { host: HOST, user: USER, password: PASSWORD }` and a correct JQL string or JQL url"
              else
                respond "You need to supply a correct JQL string or JQL url: #{error_message}"
              end
            else
              topic = :no_topic if topic == ""
              @teams[team_name.to_sym][:memos] ||= []
              if @teams[team_name.to_sym][:memos].empty? and !@teams[team_name.to_sym].key?(:last_memo_id)
                memo_id = 1
              else
                if @teams[team_name.to_sym].key?(:last_memo_id)
                  memo_id = @teams[team_name.to_sym][:last_memo_id] + 1
                else
                  memo_id = @teams[team_name.to_sym][:memos].memo_id.flatten.max + 1 #backwards compatibility
                end
              end
              @teams[team_name.to_sym][:last_memo_id] = memo_id
              @teams[team_name.to_sym][:memos] << {
                memo_id: memo_id,
                topic: topic,
                type: type,
                privacy: privacy,
                user: "#{user.team_id}_#{user.name}",
                date: Time.now.strftime("%Y-%m-%dT%H:%M:%S.000Z")[0..18],
                message: message,
                status: ":new: ",
                search: search,
                issues: [],
                comments: [],
              }
              update_teams()
              respond "The memo has been added to *#{team_name}* team. (#{memo_id})"
            end
          end
        end
      end
    end
  end
end
