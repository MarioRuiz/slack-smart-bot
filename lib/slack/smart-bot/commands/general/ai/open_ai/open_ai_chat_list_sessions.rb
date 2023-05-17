class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat_list_sessions(type, tag: '') #type can be :own or :public or :shared
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
                    
                    if tag == '' or (session.key?(:tag) and tag == session[:tag])
                      list_sessions << "*`#{session_name}`*: "
                      list_sessions[-1]<<"_#{session[:description]}_ " if session.key?(:description) and session[:description].to_s.strip != ''
                      list_sessions[-1]<<"*(public)* " if session.key?(:public) and session[:public] and type != :public
                      list_sessions[-1]<<"(shared on <##{session.shared.join(">, <#")}>) " if session.key?(:shared) and session[:shared].size > 0 and type != :shared
                      list_sessions[-1]<<"\n     *#{session.num_prompts}* prompts. "
                      list_sessions[-1]<<" tag: >*#{session.tag}*. " if session.key?(:tag) and session[:tag] != '' and tag == ''
                      list_sessions[-1]<<"shared by: *#{session.user_creator}*. " if type != :own
                      list_sessions[-1]<<"original creator: *#{session.copy_of_user}*. " if session.key?(:copy_of_user) and session[:copy_of_user] != '' and session[:copy_of_user] != session[:user_creator]
                      list_sessions[-1]<<"model: #{session.model}. " if session.key?(:model) and session[:model] != ''
                      list_sessions[-1]<<"copies: #{session.users_copying.size}. " if session.key?(:users_copying) and session[:users_copying].size > 0
                      list_sessions[-1]<<"users: #{session.users_copying.uniq.size}. " if session.key?(:users_copying) and session[:users_copying].size > 0
                      list_sessions[-1]<<"collaborators: *#{session.collaborators.join(", ")}*. " unless !session.key?(:collaborators) or session.collaborators.empty?
                      list_sessions[-1]<<"last prompt: #{session.last_activity.gsub("-", "/")[0..15]}. " if type == :own
                    end
                  end
                end
              end
            end
            if list_sessions.size > 0
              list_sessions[-1] << "\n\n:information_source: To start using a session: `chatgpt use USER_SHARED SESSION_NAME`" if type != :own
              if type == :own
                respond "*GPT*: Your#{" >*#{tag}*" if tag!=''} sessions:\n\n#{list_sessions.join("\n\n")}"
              elsif type == :public
                respond "*GPT*: Public#{" >*#{tag}*" if tag!=''} sessions:\n\n#{list_sessions.join("\n\n")}"
              elsif type == :shared
                respond "*GPT*: Shared#{" >*#{tag}*" if tag!=''} sessions on <##{channel}>:\n\n#{list_sessions.join("\n\n")}"
              end
            else
              if type == :own
                respond "*GPT*: You don't have any#{" >*#{tag}*" if tag!=''} sessions."
              else
                respond "*GPT*: There are no#{" >*#{tag}*" if tag!=''} #{type} sessions."
              end                
            end

          end
        end
      end
    end
  end
end
