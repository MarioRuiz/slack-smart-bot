class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat_list_sessions()
            save_stats(__method__)

            user = Thread.current[:user].dup
            @active_chat_gpt_sessions[user.name] ||= {}

            if @open_ai.key?(user.name) and @open_ai[user.name].key?(:chat_gpt) and @open_ai[user.name][:chat_gpt].key?(:sessions) and
               @open_ai[user.name][:chat_gpt][:sessions].size > 0
              sessions = @open_ai[user.name][:chat_gpt][:sessions].keys.sort
              sessions.delete("")
              list_sessions = []
              sessions.each do |session_name|
                session = @open_ai[user.name][:chat_gpt][:sessions][session_name]
                list_sessions << "*`#{session_name}`*: *#{session.num_prompts}* prompts#{", collaborators: *#{session.collaborators.join(", ")}*" unless !session.key?(:collaborators) or session.collaborators.empty?}. _(#{session.started.gsub("-", "/")[0..15]} - #{session.last_activity.gsub("-", "/")[0..15]})_"
              end
              respond "*GPT*: Your sessions are:\n#{list_sessions.join("\n")}"
            else
              respond "*GPT*: You don't have any session saved."
            end
          end
        end
      end
    end
  end
end
