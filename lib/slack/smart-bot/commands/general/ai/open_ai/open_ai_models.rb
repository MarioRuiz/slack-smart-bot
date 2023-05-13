class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_models(model='')
            save_stats(__method__)
            get_personal_settings()
            @ai_open_ai, message_connect = SlackSmartBot::AI::OpenAI.connect(@ai_open_ai, config, @personal_settings)
            respond message_connect if message_connect
            user = Thread.current[:user]
            if !@ai_open_ai[user.name].nil? and !@ai_open_ai[user.name][:chat_gpt][:client].nil?
                react :running
                begin
                  res = SlackSmartBot::AI::OpenAI.models(@ai_open_ai[user.name][:chat_gpt][:client], @ai_open_ai[user.name][:chat_gpt], model)
                  if model == ''
                    message = ["*OpenAI*"]
                    message << "To start a chatGPT session using a specific model: `^chatgpt SESSION_NAME MODEL_NAME`"
                    message << "For example: `^chatgpt data_analysis gpt-35-turbo-0301`"
                    message << "If you want to use a model by default, you can use on a DM with the SmartBot the command"
                    message << "`set personal settings ai.open_ai.chat_gpt.model MODEL_NAME`"
                    message << "`set personal settings ai.open_ai.whisper.model MODEL_NAME`"
                    message << "Here are the models available for use:"
                    message << "```#{res.strip}```"
                    respond message.join("\n")
                  else
                    respond "*OpenAI* Info about #{model} model:\n```#{res.strip}```"
                  end
                rescue => exception
                  @logger.warn "Error in open_ai_models: #{exception}"
                  respond "*OpenAI*: Sorry, I'm having some problems. OpenAI probably is not available. Please try again later."
                end
                unreact :running
            end
          end
        end
      end
    end
  end
end
