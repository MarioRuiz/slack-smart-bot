class SlackSmartBot
  module Commands
    module General
      module Teams
        module Memos
          def set_memo_status(user, team_name, memo_id, status)
            save_stats(__method__) if answer.empty?

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

            if !@teams.key?(team_name.to_sym)
              respond "It seems like the team *#{team_name}* doesn't exist.\nRelated commands `add team TEAM_NAME PROPERTIES`, `see team TEAM_NAME`, `see teams`"
            elsif !(all_team_members + config.team_id_masters).flatten.include?("#{user.team_id}_#{user.name}")
              respond "You have to be a member of the team or a Master admin to be able to set the status of a memo."
            elsif !@teams[team_name.to_sym].key?(:memos) or @teams[team_name.to_sym][:memos].empty? or !@teams[team_name.to_sym][:memos].memo_id.include?(memo_id.to_i)
              respond "It seems like there is no memo with id #{memo_id}"
            elsif @teams[team_name.to_sym][:memos].memo_id.include?(memo_id.to_i)
              memo_selected = @teams[team_name.to_sym][:memos].select { |m| m.memo_id == memo_id.to_i }[-1]
              if memo_selected.type == "jira" or memo_selected.type == "github"
                #todo: add tests for jira and github
                respond "The memo specified is a #{memo_selected.type} and the status in those cases are linked to the specific issues in #{memo_selected.type}."
              elsif memo_selected.privacy == "personal" and memo_selected.user != "#{user.team_id}_#{user.name}"
                respond "Only the creator can set the status of a personal memo."
              else
                answer_delete
                memos = []
                message = ""
                get_teams()
                @teams[team_name.to_sym][:memos].each do |memo|
                  if memo.memo_id == memo_id.to_i
                    memo.status = status
                    message = memo.message
                  end
                  memos << memo
                end
                @teams[team_name.to_sym][:memos] = memos
                update_teams()
                respond "The memo status has been updated on team #{team_name}: #{message}"
              end
            end
          end
        end
      end
    end
  end
end
