class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_generate_image(message, delete_history = false, repeat: false)
            save_stats(__method__)
            get_personal_settings()
            @ai_open_ai, message_connect = SlackSmartBot::AI::OpenAI.connect(@ai_open_ai, config, @personal_settings, reconnect: delete_history, service: :dall_e)
            respond message_connect if message_connect
            user = Thread.current[:user].dup
            team_id = user.team_id 
            team_id_user = Thread.current[:team_id_user]

            if !@ai_open_ai[team_id_user].nil? and !@ai_open_ai[team_id_user][:dall_e][:client].nil?
              @ai_open_ai_image ||= {}
              @ai_open_ai_image[team_id_user] ||= []
              react :art
              begin
                @ai_open_ai_image[team_id_user] = [] if delete_history
                if delete_history and message == ""
                  respond "*OpenAI*: Let's start a new image generation. Use `?i PROMPT` to generate an image."
                elsif repeat and @ai_open_ai_image[team_id_user].empty? and message == ""
                  respond "*OpenAI*: Sorry, I need to generate an image first. Use `?i PROMPT` to generate an image."
                else
                  @ai_open_ai_image[team_id_user] << message unless repeat
                  success, res = SlackSmartBot::AI::OpenAI.send_image_generation(@ai_open_ai[team_id_user][:dall_e][:client], @ai_open_ai_image[team_id_user].join("\n"), @ai_open_ai[team_id_user][:dall_e][:image_size])
                  if success
                    urls = res
                    urls = [urls] if urls.is_a?(String)
                    urls.delete({})
                    if urls.nil? or urls.empty?
                      respond "*OpenAI*: Sorry, I'm having some problems. OpenAI was not able to generate an image."
                    else
                      session_name = @ai_open_ai_image[team_id_user].first[0..29]
                      messagersp = "OpenAI Session: _<#{session_name}...>_ (id:#{@ai_open_ai_image[team_id_user].object_id})"
                      message = "Repeat" if repeat
                      require "uri"
                      urls.each do |url|
                        uri = URI.parse(url)
                        require "nice_http"
                        http = NiceHttp.new(host: "https://#{uri.host}")
                        Dir.mkdir("#{config.path}/tmp") unless Dir.exist?("#{config.path}/tmp")
                        file_path_name = "#{config.path}/tmp/#{team_id_user}_#{@ai_open_ai_image[team_id_user].object_id}.png"
                        res = http.get(uri.path + "?#{uri.query}", save_data: file_path_name)
                        if config.simulate
                          respond "file: #{file_path_name}, #{messagersp}, #{message}, image/png, png"
                        else
                          send_file(Thread.current[:dest], messagersp, file_path_name, message, "image/png", "png")
                        end
                        http.close unless http.nil?
                      end
                    end
                  else
                    respond res
                  end
                end
              rescue => exception
                respond "*OpenAI*: Sorry, I'm having some problems. OpenAI probably is not available. Please try again later."
                @logger.warn exception
              end
              unreact :art
            end
          end
        end
      end
    end
  end
end
