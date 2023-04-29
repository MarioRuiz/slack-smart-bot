class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_whisper(message, files)
            save_stats(__method__)
            get_personal_settings()
            @ai_open_ai, message_connect = SlackSmartBot::AI::OpenAI.connect(@ai_open_ai, config, @personal_settings, service: :whisper)
            respond message_connect if message_connect
            user = Thread.current[:user]
            if !@ai_open_ai[user.name].nil? and !@ai_open_ai[user.name][:whisper][:client].nil?
              react :speech_balloon 
              begin
                if files.nil? or files.size != 1
                  respond "*OpenAI Whisper*: Sorry, I need an audio file to transcribe. Please upload an audio file and try again."
                else
                  require "nice_http"
                  audio = "#{config.path}/tmp/#{user.name}_audio.wav"
                  http = NiceHttp.new(host: "https://files.slack.com", headers: { "Authorization" => "Bearer #{config.token}" })
                  res = http.get(files[0].url_private_download, save_data: audio)
                  success, res = SlackSmartBot::AI::OpenAI.whisper_transcribe(@ai_open_ai[user.name][:whisper][:client], @ai_open_ai[user.name].whisper_model, audio)
                  if success
                    if message.to_s != ''
                      success, res = SlackSmartBot::AI::OpenAI.send_gpt_chat(@ai_open_ai[user.name][:whisper][:client], @ai_open_ai[user.name].gpt_model, "#{message}:\n#{res}")
                      type_whisper = message
                    else
                      type_whisper = "Transcribe"
                    end
                    if res.size > 3000
                      send_file(Thread.current[:dest], "*OpenAI Whisper*", '', type_whisper, "text/plain", "text", content: res)
                    else
                      respond "*OpenAI Whisper* \n#{res.strip}"
                    end
                  else
                    respond "*OpenAI Whisper* \n#{res.strip}"
                  end
                  File.delete(audio) if File.exist?(audio)
                end
              rescue => exception
                respond "*OpenAI Whisper*: Sorry, I'm having some problems. OpenAI probably is not available. Please try again later."
                @logger.warn exception
              end
              unreact :speech_balloon
            end
          end
        end
      end
    end
  end
end
