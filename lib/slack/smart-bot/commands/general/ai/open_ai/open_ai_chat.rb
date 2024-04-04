class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat(message, delete_history, type, model: '', tag: '', description: '', files: [])
            get_personal_settings()
            user = Thread.current[:user].dup
            user_name = user.name
            team_id = user.team_id
            team_id_user = Thread.current[:team_id_user]
            if model != '' and !@open_ai_models.include?(model)
              open_ai_models('', just_models: true) if @open_ai_models.empty?
              model_selected = @open_ai_models.select{|m| m.include?(model)}
              model = model_selected[0] if model_selected.size == 1
            end

            @active_chat_gpt_sessions[team_id_user] ||= {}
            if delete_history
              @active_chat_gpt_sessions[team_id_user][Thread.current[:dest]] = ''
              session_name = ''
            end

            if @active_chat_gpt_sessions[team_id_user].key?(Thread.current[:thread_ts]) and Thread.current[:thread_ts]!='' #added and Thread.current[:thread_ts]!='' for testing when SIMULATE==true and not in a thread
              session_name = @active_chat_gpt_sessions[team_id_user][Thread.current[:thread_ts]]
            elsif @active_chat_gpt_sessions[team_id_user].key?(Thread.current[:dest])
              session_name = @active_chat_gpt_sessions[team_id_user][Thread.current[:dest]]
            else
              session_name = ''
              @active_chat_gpt_sessions[team_id_user][Thread.current[:dest]] = ''
            end
            if type == :start or type == :continue
              session_name = message
              @active_chat_gpt_sessions[team_id_user] ||= {}
              @active_chat_gpt_sessions[team_id_user][Thread.current[:thread_ts]] = session_name
              message = ''
              get_openai_sessions(session_name)
              @open_ai[team_id_user] ||= {}
              @open_ai[team_id_user][:chat_gpt] ||= {}
              @open_ai[team_id_user][:chat_gpt][:sessions] ||= {}
              if !@open_ai[team_id_user][:chat_gpt][:sessions].key?(session_name)
                @open_ai[team_id_user][:chat_gpt][:sessions][session_name] = {
                  team_creator: team_id,
                  user_creator: user_name,
                  started: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
                  last_activity: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
                  collaborators: [],
                  num_prompts: 0,
                  model: model,
                  copy_of_session: '',
                  copy_of_team: '',
                  copy_of_user: '',
                  users_copying: [],
                  public: false,
                  shared: [],
                  description: description,
                  tag: tag.downcase
                }
              else # type == :continue or loading
                @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:model] = model if model != ''
                num_prompts = @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:num_prompts]
                respond "*ChatGPT*: I just loaded *#{session_name}*.\nThere are *#{num_prompts} prompts* in this session.\nThis was the *last prompt* from the session:\n"
                content = @ai_gpt[team_id_user][session_name].join("\n")
                index_last_prompt = content.rindex(/^(Me>\s.*)$/)
                if index_last_prompt.nil?
                  respond "No prompts found"
                else
                  last_prompt = content[index_last_prompt..-1].gsub(/^Me>/, '*Me>*').gsub(/^chatGPT>/i, "\n*ChatGPT>*")
                  respond last_prompt
                end
              end
              if Thread.current[:on_thread] and
                  (Thread.current[:thread_ts] == Thread.current[:ts] or
                    ( @open_ai[team_id_user][:chat_gpt][:sessions].key?(session_name) and
                      @open_ai[team_id_user][:chat_gpt][:sessions][session_name].key?(:thread_ts) and
                      @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:thread_ts].include?(Thread.current[:thread_ts]) ) )
                react :running, Thread.current[:thread_ts]
                @listening[team_id_user] ||= {}
                @listening[team_id_user][Thread.current[:thread_ts]] = Time.now
                @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:thread_ts] ||= []

                @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:thread_ts] << Thread.current[:thread_ts]
                @listening[:threads][Thread.current[:thread_ts]] = Thread.current[:dest]
              else
                @active_chat_gpt_sessions[team_id_user][Thread.current[:dest]] = session_name
              end
              @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:description] = description if description != ''
              @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:tag] = tag.downcase if tag != ''
              open_ai_chat_use_model(model, dont_save_stats: true) if model != ''
            elsif type == :temporary and
              (!@chat_gpt_collaborating.key?(team_id_user) or !@chat_gpt_collaborating[team_id_user].key?(Thread.current[:thread_ts]))

              @open_ai[team_id_user] ||= {}
              @open_ai[team_id_user][:chat_gpt] ||= {}
              @open_ai[team_id_user][:chat_gpt][:sessions] ||= {}

              if Thread.current[:on_thread] and
                (Thread.current[:thread_ts] == Thread.current[:ts] or
                  (@open_ai[team_id_user][:chat_gpt][:sessions].key?("") and @open_ai[team_id_user][:chat_gpt][:sessions][""].key?(:thread_ts) and
                  @open_ai[team_id_user][:chat_gpt][:sessions][""][:thread_ts].include?(Thread.current[:thread_ts]) ))
                @listening[team_id_user] ||= {}
                @listening[team_id_user][Thread.current[:thread_ts]] = Time.now
                @listening[:threads][Thread.current[:thread_ts]] = Thread.current[:dest]
                react :running if Thread.current[:thread_ts] == Thread.current[:ts]
                @open_ai[team_id_user][:chat_gpt][:sessions][""] ||= {}
                @open_ai[team_id_user][:chat_gpt][:sessions][""][:thread_ts] ||= []
                @open_ai[team_id_user][:chat_gpt][:sessions][""][:thread_ts] << Thread.current[:thread_ts]
                @active_chat_gpt_sessions[team_id_user] ||= {}
                @active_chat_gpt_sessions[team_id_user][Thread.current[:thread_ts]] ||= ""
              end
            end

            #for collaborators
            if @chat_gpt_collaborating.key?(team_id_user) and @chat_gpt_collaborating[team_id_user].key?(Thread.current[:thread_ts])
              team_creator = @chat_gpt_collaborating[team_id_user][Thread.current[:thread_ts]][:team_creator]
              user_creator = @chat_gpt_collaborating[team_id_user][Thread.current[:thread_ts]][:user_creator]
              session_name = @chat_gpt_collaborating[team_id_user][Thread.current[:thread_ts]][:session_name]
              collaborator = true
            else
              team_creator = team_id
              user_creator = user_name
              collaborator = false
            end
            team_id_user_creator = team_creator + "_" + user_creator
            unless type != :temporary and
              (!@open_ai.key?(team_id_user_creator) or !@open_ai[team_id_user_creator].key?(:chat_gpt) or !@open_ai[team_id_user_creator][:chat_gpt].key?(:sessions) or
              !@open_ai[team_id_user_creator][:chat_gpt][:sessions].key?(session_name) or
              (@open_ai[team_id_user_creator][:chat_gpt][:sessions].key?(session_name) and !collaborator and user_creator!=user.name))
              save_stats(__method__)
              @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:last_activity] = Time.now.strftime("%Y-%m-%d %H:%M:%S") unless session_name == ''
              @ai_open_ai, message_connect = SlackSmartBot::AI::OpenAI.connect(@ai_open_ai, config, @personal_settings, reconnect: delete_history, service: :chat_gpt)

              respond message_connect if message_connect
              if !@ai_open_ai[team_id_user_creator].nil? and !@ai_open_ai[team_id_user_creator][:chat_gpt][:client].nil?
                @ai_gpt[team_id_user_creator] ||= {}
                @ai_gpt[team_id_user_creator][session_name] ||= []

                if delete_history or !@open_ai.key?(team_id_user_creator) or !@open_ai[team_id_user_creator].key?(:chat_gpt) or !@open_ai[team_id_user_creator][:chat_gpt].key?(:sessions) or
                  !@open_ai[team_id_user_creator][:chat_gpt][:sessions].key?(session_name) or !@open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name].key?(:model) or
                  !@open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name].key?(:num_prompts)

                  if delete_history and session_name == '' && @open_ai.key?(team_id_user_creator) && @open_ai[team_id_user_creator].key?(:chat_gpt) &&
                    @open_ai[team_id_user_creator][:chat_gpt].key?(:sessions) && @open_ai[team_id_user_creator][:chat_gpt][:sessions].key?("") &&
                    @open_ai[team_id_user_creator][:chat_gpt][:sessions][""].key?(:thread_ts)

                    @open_ai[team_id_user_creator][:chat_gpt][:sessions][""][:thread_ts].each do |thread_ts|
                      if thread_ts != Thread.current[:thread_ts] && @listening[:threads].key?(thread_ts)
                        unreact :running, thread_ts, channel: @listening[:threads][thread_ts]
                        message_chatgpt = "I'm sorry, but I'm no longer listening to this thread since you started a new temporary session."
                        respond message_chatgpt, @listening[:threads][thread_ts], thread_ts: thread_ts
                        @listening[team_id_user_creator].delete(thread_ts)
                        @listening[:threads].delete(thread_ts)
                      end
                    end
                  end

                  @open_ai[team_id_user_creator] ||= {}
                  @open_ai[team_id_user_creator][:chat_gpt] ||= {}
                  @open_ai[team_id_user_creator][:chat_gpt][:sessions] ||= {}
                  @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name] ||= {}
                  @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:model] = model
                  @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:num_prompts] = 0
                end

                if message == "" and session_name == '' # ?? is called
                  @ai_gpt[team_id_user_creator][session_name] = []
                  respond "*ChatGPT*: Let's start a new temporary conversation. Ask me anything."
                  open_ai_chat_use_model(model, dont_save_stats: true) if model != ''
                else
                  react :speech_balloon
                  begin
                    urls_messages = []
                    get_openai_sessions(session_name, team_id: team_creator, user_name: user_creator)
                    @ai_gpt[team_id_user_creator][session_name] = [] if delete_history
                    if @open_ai.key?(team_id_user_creator) and @open_ai[team_id_user_creator].key?(:chat_gpt) and @open_ai[team_id_user_creator][:chat_gpt].key?(:sessions) and
                      @open_ai[team_id_user_creator][:chat_gpt][:sessions].key?(session_name) and @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name].key?(:model)
                      if model == ''
                        model = @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:model].to_s
                      else
                        @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:model] = model
                      end
                    else
                      model = ''
                    end
                    model = @ai_open_ai[team_id_user_creator].chat_gpt.model if model.empty?
                    if message == ''
                      res = ''
                    else
                      if !files.nil? and files.size == 1
                        http = NiceHttp.new(host: "https://files.slack.com", headers: { "Authorization" => "Bearer #{config.token}" })
                        res = http.get(files[0].url_private_download)
                        message = "#{message}\n\n#{res.data}"
                      end

                      @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:num_prompts] += 1
                      urls = message.scan(/!(https?:\/\/[\S]+)/).flatten
                      urls.uniq.each do |url|
                        begin
                            parsed_url = URI.parse(url)

                            headers = {}
                            authorizations = {}

                            if config.key?(:authorizations)
                              config[:authorizations].each do |key, value|
                                if value.key?(:host)
                                  authorizations[value[:host]] = value
                                end
                              end
                            end

                            if @personal_settings_hash.key?(team_id_user) and @personal_settings_hash[team_id_user].key?(:authorizations)
                              @personal_settings_hash[team_id_user][:authorizations].each do |key, value|
                                if value.key?(:host)
                                  authorizations[value[:host]] = value
                                end
                              end
                            end

                            authorizations.each do |key, value|
                              if key.match?(/^(https:\/\/|http:\/\/)?#{parsed_url.host.gsub('.','\.')}/)
                                value.each do |k, v|
                                  headers[k.to_sym] = v unless k == :host
                                end
                              end
                            end

                            domain = "#{parsed_url.scheme}://#{parsed_url.host}"
                            http = NiceHttp.new(host: domain, headers: headers, log: :no)
                            response = http.get(parsed_url.path)
                            html_doc = Nokogiri::HTML(response.body)
                            html_doc.search('script, style').remove
                            text = html_doc.text.strip
                            text.gsub!(/^\s*$/m, "")
                            urls_messages << "> #{url}: content extracted and added to prompt\n"
                            http.close
                        rescue Exception => e
                            text = "Error: #{e.message}"
                            urls_messages << "> #{url}: #{text}\n"
                        end
                        message.gsub!("!#{url}", '')
                        message += "\n #{text}\n"
                      end

                      @ai_gpt[team_id_user_creator][session_name] << "Me> #{message}"
                      prompts = @ai_gpt[team_id_user_creator][session_name].join("\n\n")
                      prompts.gsub!(/^Me>\s*/,'')
                      prompts.gsub!(/^chatGPT>\s*/,'')
                      success, res = SlackSmartBot::AI::OpenAI.send_gpt_chat(@ai_open_ai[team_id_user_creator][:chat_gpt][:client], model, prompts, @ai_open_ai[team_id_user_creator].chat_gpt)
                      if success
                        @ai_gpt[team_id_user_creator][session_name] << "chatGPT> #{res}"
                      end
                    end
                    if session_name == ''
                      temp_session_name = @ai_gpt[team_id_user_creator][''].first[0..35].gsub('Me> ','')
                      respond "*ChatGPT* Temporary session: _<#{temp_session_name.gsub("\n",' ').gsub("`",' ')}...>_ model: #{model}\n#{res.to_s.strip}"
                      if res.to_s.strip == ''
                        respond "It seems like GPT is not responding. Please try again later or use another model, as it might be overloaded."
                      end
                      #to avoid logging the prompt or the response
                      if config.encrypt
                        Thread.current[:encrypted] ||= []
                        Thread.current[:encrypted] << message
                      end
                    elsif res.to_s.strip == ''
                      res = "\nAll prompts were removed from session." if delete_history
                      respond "*ChatGPT* Session _<#{session_name}>_ model: #{model}#{res}"
                      respond "It seems like GPT is not responding. Please try again later or use another model, as it might be overloaded." if message != ''
                    else
                      respond "*ChatGPT* Session _<#{session_name}>_ model: #{model}\n#{res.to_s.strip}"
                    end
                    if urls_messages.size > 0
                      respond urls_messages.join("\n")
                    end
                    update_openai_sessions(session_name, team_id: team_creator, user_name: user_creator) unless session_name == ''
                  rescue => exception
                    respond "*ChatGPT*: Sorry, I'm having some problems. OpenAI probably is not available. Please try again later."
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
  end
end
