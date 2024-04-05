class SlackSmartBot
  module Commands
    module General
      module Teams
        module Memos
          def add_memo_team_comment(user, team_name, memo_id, message)
            save_stats(__method__)

            get_teams()
            team_name = team_name.to_sym
            if @teams.key?(team_name)
              if @teams[team_name].key?(:memos)
                memo = @teams[team_name].memos.select { |m| m.memo_id == memo_id.to_i }[-1]
                if memo
                  memo.comments ||= []
                  memo.comments << { user_name: "#{user.team_id}_#{user.name}", user_id: user.id, message: message, time: Time.now.to_s }
                  update_teams()
                  if config.simulate
                    respond "Comment added to memo #{memo_id} in team #{team_name}"
                  else
                    react :spiral_note_pad
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
