class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat(message, delete_history)
            save_stats(__method__)
            get_personal_settings()
            @ai_open_ai, message_connect = SlackSmartBot::AI::OpenAI.connect(@ai_open_ai, config, @personal_settings, reconnect: delete_history)
            respond message_connect if message_connect
            user = Thread.current[:user]
            if !@ai_open_ai[user.name].nil? and !@ai_open_ai[user.name][:client].nil?
              @ai_gpt ||= {}
              @ai_gpt[user.name] ||= []

              if message == "" # ?? is called
                @ai_gpt[user.name] = []
                respond "*GPT*: Let's start a new conversation. Ask me anything."
              else
                react :speech_balloon
                begin
                  @ai_gpt[user.name] = [] if delete_history
                  @ai_gpt[user.name] << message
                  success, res = SlackSmartBot::AI::OpenAI.send_gpt_chat(@ai_open_ai[user.name][:client], @ai_open_ai[user.name].gpt_model, @ai_gpt[user.name].join("\n"))
                  if success
                    @ai_gpt[user.name] << res
                  end
                  respond "*GPT* Session: _<#{@ai_gpt[user.name].first[0..29]}...>_ (id:#{@ai_gpt[user.name].object_id}) \n#{res.strip}"
                rescue => exception
                  respond "*GPT*: Sorry, I'm having some problems. OpenAI probably is not available. Please try again later."
                end
                unreact :speech_balloon
              end
            end
          end
        end
      end
    end
  end
end
