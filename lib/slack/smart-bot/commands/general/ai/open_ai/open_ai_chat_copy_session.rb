class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat_copy_session(session_name, new_session_name)
            save_stats(__method__)

            user = Thread.current[:user].dup
            @open_ai[user.name] ||= {}
            @open_ai[user.name][:chat_gpt] ||= {}
            @open_ai[user.name][:chat_gpt][:sessions] ||= {}
            if @open_ai[user.name][:chat_gpt][:sessions].key?(session_name)
                session_orig = @open_ai[user.name][:chat_gpt][:sessions][session_name]
                open_ai_new_session = {
                    user_creator: user.name,     
                    started: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
                    last_activity: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
                    collaborators: [],
                    num_prompts: session_orig[:num_prompts],
                    model: session_orig[:model]
                }
                new_session_name = session_name if new_session_name == ''
                session_names = @open_ai[user.name][:chat_gpt][:sessions].keys
                if session_names.include?(new_session_name)
                    number = session_names.join("\n").scan(/^#{new_session_name}(\d+)$/).max
                    if number.nil?
                        number = '1'
                    else
                        number = number.flatten[-1].to_i + 1
                    end
                    new_session_name = "#{new_session_name}#{number}"
                end
                @open_ai[user.name][:chat_gpt][:sessions][new_session_name] = open_ai_new_session

                get_openai_sessions(session_name, user_name: user.name)
                @ai_gpt[user.name][new_session_name] = @ai_gpt[user.name][session_name].dup
                update_openai_sessions(new_session_name, user_name: user.name)
                respond "*GPT*: Session #{session_name} copied to #{new_session_name}.\nNow you can call `chatGPT #{new_session_name}` to use it."
            else
                respond "*GPT*: You don't have a session with that name.\nCall `chatGPT list sessions` to see your saved sessions."
            end
          end
        end
      end
    end
  end
end
