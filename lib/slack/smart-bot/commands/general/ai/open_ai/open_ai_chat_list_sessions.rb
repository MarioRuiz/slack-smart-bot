class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat_list_sessions(type) #type can be :own or :public or :shared
            save_stats(__method__)

            user = Thread.current[:user].dup
            channel = Thread.current[:dest]

            get_openai_sessions()
            check_users = []
            if type == :own
              check_users << user.name
            else
              check_users = @open_ai.keys
            end

            list_sessions = []
            check_users.each do |user_name|
              if @open_ai.key?(user_name) and @open_ai[user_name].key?(:chat_gpt) and 
                @open_ai[user_name][:chat_gpt].key?(:sessions) and
                @open_ai[user_name][:chat_gpt][:sessions].size > 0

                sessions = @open_ai[user_name][:chat_gpt][:sessions].keys.sort
                sessions.delete("")
                sessions.each do |session_name|
                  session = @open_ai[user_name][:chat_gpt][:sessions][session_name]
                  if (type == :own and session[:user_creator] == user.name) or
                    (type == :public and session.key?(:public) and session[:public]) or
                    (type == :shared and session.key?(:shared) and session[:shared].include?(channel))

                    list_sessions << "*`#{session_name}`*: "
                    list_sessions[-1]<<"_#{session[:description]}_ " if session.key?(:description) and session[:description] != ''
                    list_sessions[-1]<<"*(public)* " if session.key?(:public) and session[:public]
                    list_sessions[-1]<<"(shared on <##{session.shared.join(">, <#")}>) " if session.key?(:shared) and session[:shared].size > 0
                    list_sessions[-1]<<"\n     *#{session.num_prompts}* prompts. "
                    list_sessions[-1]<<"creator: *#{session.user_creator}*. " if type != :own
                    list_sessions[-1]<<"model: #{session.model}. " if session.key?(:model) and session[:model] != ''
                    list_sessions[-1]<<"collaborators: *#{session.collaborators.join(", ")}*. " unless !session.key?(:collaborators) or session.collaborators.empty?
                    list_sessions[-1]<<"last activity: #{session.last_activity.gsub("-", "/")[0..15]}. "
                  end
                end
              end
            end
            if list_sessions.size > 0
              if type == :own
                respond "*GPT*: Your sessions are:\n\n#{list_sessions.join("\n\n")}"
              elsif type == :public
                respond "*GPT*: Public sessions are:\n\n#{list_sessions.join("\n\n")}"
              elsif type == :shared
                respond "*GPT*: Shared sessions on <##{channel}> are:\n\n#{list_sessions.join("\n\n")}"
              end
            else
              respond "*GPT*: There are no sessions."
            end

          end
        end
      end
    end
  end
end
