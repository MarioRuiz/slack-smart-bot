class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat_get_prompts(session_name)
            save_stats(__method__)

            user = Thread.current[:user].dup
            @active_chat_gpt_sessions[user.name] ||= {}

            get_openai_sessions(session_name)
            
            if @open_ai[user.name][:chat_gpt][:sessions].key?(session_name)
              prompts = @ai_gpt[user.name][session_name].join("\n")
              prompts.gsub!(/^Me>\s*/, "\nMe> ")
              prompts.gsub!(/^chatGPT>\s*/, "\nchatGPT> ")
              if prompts.length > 3000
                respond "*GPT*: Session *#{session_name}*."
                send_file(Thread.current[:dest], "", "prompts.txt", "", "text/plain", "text", content: prompts)
              elsif prompts.empty?
                respond "*GPT*: Session *#{session_name}* has no prompts."
              else
                respond "*GPT*: Session *#{session_name}*."
                if prompts.include?("`")
                  respond prompts
                else
                  respond "```#{prompts}```"
                end
              end
            else
              respond "*GPT*: You don't have a session with that name.\nCall `chatGPT list sessions` to see your saved sessions."
            end
          end
        end
      end
    end
  end
end
