class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat_copy_session(user_orig, session_name, new_session_name)
            if user_orig == ""
              save_stats(__method__)
            else
              save_stats(:open_ai_chat_copy_session_from_user)
            end

            user = Thread.current[:user].dup
            user_orig = user.name if user_orig == ""
            dest = Thread.current[:dest]
            get_openai_sessions()

            if !@open_ai.key?(user_orig)
              respond "*GPT*: The user *#{user_orig}* doesn't exist."
            elsif !@open_ai[user_orig][:chat_gpt][:sessions].key?(session_name)
              respond "*GPT*: The session *#{session_name}* doesn't exist."
            elsif user_orig != user.name and
              !@open_ai[user_orig][:chat_gpt][:sessions][session_name][:public] and
                  !@open_ai[user_orig][:chat_gpt][:sessions][session_name][:shared].include?(dest)
              respond "*GPT*: The session *#{session_name}* doesn't exist or it is not shared."
            else
              @open_ai[user.name] ||= {}
              @open_ai[user.name][:chat_gpt] ||= {}
              @open_ai[user.name][:chat_gpt][:sessions] ||= {}  
              session_orig = @open_ai[user_orig][:chat_gpt][:sessions][session_name]
              open_ai_new_session = {
                user_creator: user.name,
                started: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
                last_activity: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
                collaborators: [],
                num_prompts: session_orig[:num_prompts],
                model: session_orig[:model],
                shared: [],
                copy_of_session: session_name,
                copy_of_user: user_orig,
                users_copying: [],
                public: false,
                description: session_orig[:description],
                tag: session_orig[:tag]
              }
              new_session_name = session_name if new_session_name == ""
              session_names = @open_ai[user.name][:chat_gpt][:sessions].keys
              if session_names.include?(new_session_name)
                number = session_names.join("\n").scan(/^#{new_session_name}(\d+)$/).max
                if number.nil?
                  number = "1"
                else
                  number = number.flatten[-1].to_i + 1
                end
                new_session_name = "#{new_session_name}#{number}"
              end
              @open_ai[user.name][:chat_gpt][:sessions][new_session_name] = open_ai_new_session

              if user_orig != user.name
                @open_ai[user_orig][:chat_gpt][:sessions][session_name][:users_copying] ||= []
                @open_ai[user_orig][:chat_gpt][:sessions][session_name][:users_copying] << user.name
                update_openai_sessions("", user_name: user_orig)
              end

              get_openai_sessions(session_name, user_name: user_orig)
              @ai_gpt[user.name] ||= {}
              @ai_gpt[user.name][new_session_name] = @ai_gpt[user_orig][session_name].dup
              update_openai_sessions(new_session_name, user_name: user.name)
              if user_orig != user.name
                respond "*GPT*: Session #{session_name} (#{user_orig}) copied to #{new_session_name}.\nNow you can call `^chatGPT #{new_session_name}` to use it."
              else
                respond "*GPT*: Session #{session_name} copied to #{new_session_name}.\nNow you can call `^chatGPT #{new_session_name}` to use it."
              end
            end
          end
        end
      end
    end
  end
end
