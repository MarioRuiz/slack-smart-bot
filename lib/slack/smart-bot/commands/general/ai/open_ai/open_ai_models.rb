class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_models(model='', just_models: false)
            save_stats(__method__) unless just_models
            get_personal_settings()
            @ai_open_ai, message_connect = SlackSmartBot::AI::OpenAI.connect(@ai_open_ai, config, @personal_settings, service: :models)
            respond message_connect if message_connect
            user = Thread.current[:user].dup
            team_id = user.team_id
            team_id_user = Thread.current[:team_id_user]
            if !@ai_open_ai[team_id_user].nil? and !@ai_open_ai[team_id_user][:models][:client].nil?
                react :running unless just_models
                begin
                  res = SlackSmartBot::AI::OpenAI.models(@ai_open_ai[team_id_user][:models][:client], @ai_open_ai[team_id_user][:models], model)
                  if model == '' or model == 'chatgpt'
                    unless just_models
                      message = ["*OpenAI*"]
                      message << "To start a chatGPT session using a specific model: `^chatgpt SESSION_NAME MODEL_NAME`"
                      message << "For example: `^chatgpt data_analysis gpt-35-turbo-0301`"
                      message << "If you want to use a model by default, you can use on a DM with the SmartBot the command"
                      message << "`set personal settings ai.open_ai.chat_gpt.model MODEL_NAME`"
                      message << "`set personal settings ai.open_ai.whisper.model MODEL_NAME`" if model == ''
                      message << "Here are the #{"#{model} " if model!=''}models available for use:"
                      message << "```#{res.strip}```"
                      respond message.join("\n")
                    end
                    @open_ai_models = res.split("\n") if model == ''
                  else
                    if just_models
                      return res
                    else
                      respond "*OpenAI* Info about #{model} model:\n```#{res.strip}```"
                    end
                  end
                rescue => exception
                  @logger.warn "Error in open_ai_models: #{exception}"
                  respond "*OpenAI*: Sorry, I'm having some problems. OpenAI probably is not available. Please try again later."
                end
                unreact :running unless just_models
            end
          end
        end
      end
    end
  end
end
