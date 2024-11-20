class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat_get_prompts(session_name)
            save_stats(__method__)

            team_id_user = Thread.current[:team_id_user]

            @active_chat_gpt_sessions[team_id_user] ||= {}

            get_openai_sessions(session_name)

            if @open_ai[team_id_user][:chat_gpt][:sessions].key?(session_name)
              prompts = ""
              prompts_array = @ai_gpt[team_id_user][session_name]
              prompts_array.each do |prompt|
                if prompt[:role] == "user" and prompt[:content].size > 0 and prompt[:content][0][:type] == "text"
                  if prompt[:content][0].key?(:clean_text)
                    #if not a static content
                    if @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:static_content].nil? or
                       !@open_ai[team_id_user][:chat_gpt][:sessions][session_name][:static_content].include?(prompt[:content][0][:clean_text])
                      prompts += "\n\n:runner: *User>* #{prompt[:content][0][:clean_text]}\n"
                    end
                  else
                    prompts += "\n\n:runner: *User>* #{prompt[:content][0][:text]}\n"
                  end
                elsif prompt[:role] == "user" and prompt[:content].size > 0 and prompt[:content][0][:type] != "text"
                  prompts += "\n\n:runner: *User>* Attached file type #{prompt[:content][0][:type]}\n"
                elsif prompt[:role] == "assistant" and prompt[:content].size > 0 and prompt[:content][0][:type] == "text"
                  prompts += "\n:speech_balloon: *chatGPT>* #{prompt[:content][0][:text]}\n"
                elsif prompt[:role] == "system" and prompt[:content].size > 0 and prompt[:content][0][:type] == "text"
                  prompts += "\n:robot_face: *Context:* #{prompt[:content][0][:text]}\n"
                else
                  prompts += "Attention! This message is not in the expected format.\n"
                end
              end
              if !@open_ai[team_id_user][:chat_gpt][:sessions][session_name][:live_content].nil? and
                 @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:live_content].size > 0
                prompts += "\n:globe_with_meridians: *Live content:*\n"
                @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:live_content].each do |live_content|
                  prompts += "\t\t - #{live_content}\n"
                end
              end
              if !@open_ai[team_id_user][:chat_gpt][:sessions][session_name][:static_content].nil? and
                 @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:static_content].size > 0
                prompts += "\n:pushpin: *Static content:*\n"
                @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:static_content].each do |static_content|
                  prompts += "\t\t - #{static_content}\n"
                end
              end
              #authorizations
              if !@open_ai[team_id_user][:chat_gpt][:sessions][session_name][:authorizations].nil? and
                 @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:authorizations].size > 0
                prompts += "\n:lock: *Authorizations:*\n"
                @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:authorizations].each do |host, header|
                  prompts += "\t\t - `#{host}`: `#{header.keys.join("`, `")}`\n"
                end
              end

              if prompts.length > 5000
                respond "*ChatGPT*: Session *#{session_name}*."
                send_file(Thread.current[:dest], "ChatGPT prompts for #{session_name}", "prompts.txt", "prompts", "text/plain", "text", content: prompts)
              elsif prompts.empty?
                respond "*ChatGPT*: Session *#{session_name}* has no prompts."
              else
                respond "*ChatGPT*: Session *#{session_name}*."
                respond transform_to_slack_markdown(prompts)
              end
            else
              respond "*ChatGPT*: You don't have a session with that name.\nCall `chatGPT list sessions` to see your saved sessions."
            end
          end
        end
      end
    end
  end
end
