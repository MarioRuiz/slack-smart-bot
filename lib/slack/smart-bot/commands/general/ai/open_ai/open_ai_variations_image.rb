class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_variations_image(message, variations, files)
            save_stats(__method__)
            get_personal_settings()
            @ai_open_ai, message_connect = SlackSmartBot::AI::OpenAI.connect(@ai_open_ai, config, @personal_settings)
            respond message_connect if message_connect
            user = Thread.current[:user]
            if !@ai_open_ai[user.name].nil? and !@ai_open_ai[user.name][:client].nil?
              if variations > 9
                respond "*OpenAI*: I'm sorry, I can only generate up to 9 variations at a time. Please try again."
              else
                variations = 1 if variations == 0
                @ai_open_ai_image ||= {}
                @ai_open_ai_image[user.name] ||= []
                react :art
                begin
                  @ai_open_ai_image[user.name] = [] if !files.nil? and files.size == 1

                  if (!File.exist?("#{config.path}/tmp/#{user.name}_#{@ai_open_ai_image[user.name].object_id}.png") and (files.nil? or files.size != 1))
                    respond "*OpenAI*: Sorry, I need to generate an image first. Use `?i PROMPT` to generate an image or upload an image to generate variations."
                  else
                    image = "#{config.path}/tmp/#{user.name}_#{@ai_open_ai_image[user.name].object_id}.png"
                    if !files.nil? and files.size == 1
                      require "nice_http"
                      http = NiceHttp.new(host: "https://files.slack.com", headers: { "Authorization" => "Bearer #{config.token}" })
                      res = http.get(files[0].url_private_download, save_data: image)
                      success, res = SlackSmartBot::AI::OpenAI.send_image_variation(@ai_open_ai[user.name].client, image, variations, size: @ai_open_ai[user.name][:image_size])
                    else
                      success, res = SlackSmartBot::AI::OpenAI.send_image_variation(@ai_open_ai[user.name].client, image, variations, size: @ai_open_ai[user.name][:image_size])
                    end
                    if success
                      urls = res
                      urls = [urls] if urls.is_a?(String)
                      if urls.nil? or urls.empty?
                        respond "*OpenAI*: Sorry, I'm having some problems. OpenAI was not able to generate an image."
                      else
                        if @ai_open_ai_image[user.name].empty?
                          session_name = "Temporary Variation"
                        else
                          session_name = @ai_open_ai_image[user.name].first[0..29]
                        end
                        messagersp = "OpenAI Session: _<#{session_name}...>_ (id:#{@ai_open_ai_image[user.name].object_id})"
                        require "uri"
                        urls.each do |url|
                          uri = URI.parse(url)
                          require "nice_http"
                          http = NiceHttp.new(host: "https://#{uri.host}")
                          file_path_name = "#{config.path}/tmp/#{user.name}_#{@ai_open_ai_image[user.name].object_id}.png"
                          res = http.get(uri.path + "?#{uri.query}", save_data: file_path_name)
                          message = "Variation #{urls.index(url)+1} of #{urls.size}"
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

            if variations > 9
              respond "*OpenAI*: I'm sorry, I can only generate up to 9 variations at a time. Please try again."
            else
            end
          end
        end
      end
    end
  end
end
