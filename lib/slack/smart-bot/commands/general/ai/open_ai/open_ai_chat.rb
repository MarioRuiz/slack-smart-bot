class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat(message, delete_history, type, model: '', tag: '', description: '', files: [])
            get_personal_settings()
            user = Thread.current[:user].dup
            @active_chat_gpt_sessions[user.name] ||= {}
            if delete_history
              @active_chat_gpt_sessions[user.name][Thread.current[:dest]] = ''
              session_name = '' 
            end
            
            if @active_chat_gpt_sessions[user.name].key?(Thread.current[:thread_ts]) and Thread.current[:thread_ts]!='' #added and Thread.current[:thread_ts]!='' for testing when SIMULATE==true and not in a thread
              session_name = @active_chat_gpt_sessions[user.name][Thread.current[:thread_ts]]
            elsif @active_chat_gpt_sessions[user.name].key?(Thread.current[:dest])
              session_name = @active_chat_gpt_sessions[user.name][Thread.current[:dest]]
            else
              session_name = ''
              @active_chat_gpt_sessions[user.name][Thread.current[:dest]] = ''
            end
            if type == :start or type == :continue
              session_name = message
              @active_chat_gpt_sessions[user.name] ||= {}
              @active_chat_gpt_sessions[user.name][Thread.current[:thread_ts]] = session_name
              message = ''
              get_openai_sessions(session_name)
              @open_ai[user.name] ||= {}
              @open_ai[user.name][:chat_gpt] ||= {}
              @open_ai[user.name][:chat_gpt][:sessions] ||= {}
              if !@open_ai[user.name][:chat_gpt][:sessions].key?(session_name)
                @open_ai[user.name][:chat_gpt][:sessions][session_name] = {          
                  user_creator: user.name,     
                  started: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
                  last_activity: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
                  collaborators: [],
                  num_prompts: 0,
                  model: model,
                  copy_of_session: '',
                  copy_of_user: '',
                  users_copying: [],
                  public: false,
                  shared: [],
                  description: description,
                  tag: tag.downcase
                }
              else # type == :continue or loading
                @open_ai[user.name][:chat_gpt][:sessions][session_name][:model] = model if model != ''
                num_prompts = @open_ai[user.name][:chat_gpt][:sessions][session_name][:num_prompts]
                respond "*ChatGPT*: I just loaded *#{session_name}*.\nThere are *#{num_prompts} prompts* in this session.\nThis was the *last prompt* from the session:\n"
                content = @ai_gpt[user.name][session_name].join("\n")
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
                    ( @open_ai[user.name][:chat_gpt][:sessions].key?(session_name) and
                      @open_ai[user.name][:chat_gpt][:sessions][session_name].key?(:thread_ts) and
                      @open_ai[user.name][:chat_gpt][:sessions][session_name][:thread_ts].include?(Thread.current[:thread_ts]) ) )
                react :running, Thread.current[:thread_ts]
                @listening[user.name] ||= {}
                @listening[user.name][Thread.current[:thread_ts]] = Time.now
                @open_ai[user.name][:chat_gpt][:sessions][session_name][:thread_ts] ||= []

                @open_ai[user.name][:chat_gpt][:sessions][session_name][:thread_ts] << Thread.current[:thread_ts]
                @listening[:threads][Thread.current[:thread_ts]] = Thread.current[:dest]
              else
                @active_chat_gpt_sessions[user.name][Thread.current[:dest]] = session_name
              end
              @open_ai[user.name][:chat_gpt][:sessions][session_name][:description] = description if description != ''
              @open_ai[user.name][:chat_gpt][:sessions][session_name][:tag] = tag.downcase if tag != ''
              open_ai_chat_use_model(model, dont_save_stats: true) if model != ''              
            elsif type == :temporary and 
              (!@chat_gpt_collaborating.key?(user.name) or !@chat_gpt_collaborating[user.name].key?(Thread.current[:thread_ts]))
              if Thread.current[:on_thread] and 
                (Thread.current[:thread_ts] == Thread.current[:ts] or 
                  (@open_ai[user.name][:chat_gpt][:sessions].key?("") and @open_ai[user.name][:chat_gpt][:sessions][""].key?(:thread_ts) and
                  @open_ai[user.name][:chat_gpt][:sessions][""][:thread_ts].include?(Thread.current[:thread_ts]) ))
                @listening[user.name] ||= {}
                @listening[user.name][Thread.current[:thread_ts]] = Time.now
                @listening[:threads][Thread.current[:thread_ts]] = Thread.current[:dest]
                react :running if Thread.current[:thread_ts] == Thread.current[:ts]
                @open_ai[user.name] ||= {}
                @open_ai[user.name][:chat_gpt] ||= {}
                @open_ai[user.name][:chat_gpt][:sessions] ||= {}
                @open_ai[user.name][:chat_gpt][:sessions][""] ||= {}
                @open_ai[user.name][:chat_gpt][:sessions][""][:thread_ts] ||= []
                @open_ai[user.name][:chat_gpt][:sessions][""][:thread_ts] << Thread.current[:thread_ts]
                @active_chat_gpt_sessions[user.name] ||= {}
                @active_chat_gpt_sessions[user.name][Thread.current[:thread_ts]] ||= ""
              end
            end
            
            #for collaborators
            if @chat_gpt_collaborating.key?(user.name) and @chat_gpt_collaborating[user.name].key?(Thread.current[:thread_ts])
              user_creator = @chat_gpt_collaborating[user.name][Thread.current[:thread_ts]][:user_creator]
              session_name = @chat_gpt_collaborating[user.name][Thread.current[:thread_ts]][:session_name]
              collaborator = true
            else
              user_creator = user.name
              collaborator = false
            end 
            unless type != :temporary and 
              (!@open_ai.key?(user_creator) or !@open_ai[user_creator].key?(:chat_gpt) or !@open_ai[user_creator][:chat_gpt].key?(:sessions) or
              !@open_ai[user_creator][:chat_gpt][:sessions].key?(session_name) or
              (@open_ai[user_creator][:chat_gpt][:sessions].key?(session_name) and !collaborator and user_creator!=user.name))
              save_stats(__method__)
              @open_ai[user_creator][:chat_gpt][:sessions][session_name][:last_activity] = Time.now.strftime("%Y-%m-%d %H:%M:%S") unless session_name == ''
              @ai_open_ai, message_connect = SlackSmartBot::AI::OpenAI.connect(@ai_open_ai, config, @personal_settings, reconnect: delete_history, service: :chat_gpt)

              respond message_connect if message_connect
              if !@ai_open_ai[user_creator].nil? and !@ai_open_ai[user_creator][:chat_gpt][:client].nil?
                @ai_gpt[user_creator] ||= {}
                @ai_gpt[user_creator][session_name] ||= []

                if delete_history or !@open_ai.key?(user_creator) or !@open_ai[user_creator].key?(:chat_gpt) or !@open_ai[user_creator][:chat_gpt].key?(:sessions) or
                  !@open_ai[user_creator][:chat_gpt][:sessions].key?(session_name) or !@open_ai[user_creator][:chat_gpt][:sessions][session_name].key?(:model) or
                  !@open_ai[user_creator][:chat_gpt][:sessions][session_name].key?(:num_prompts)

                  if delete_history and session_name == '' && @open_ai.key?(user_creator) && @open_ai[user_creator].key?(:chat_gpt) && 
                    @open_ai[user_creator][:chat_gpt].key?(:sessions) && @open_ai[user_creator][:chat_gpt][:sessions].key?("") &&
                    @open_ai[user_creator][:chat_gpt][:sessions][""].key?(:thread_ts)

                    @open_ai[user_creator][:chat_gpt][:sessions][""][:thread_ts].each do |thread_ts|
                      if thread_ts != Thread.current[:thread_ts] && @listening[:threads].key?(thread_ts)
                        unreact :running, thread_ts, channel: @listening[:threads][thread_ts]
                        message_chatgpt = "I'm sorry, but I'm no longer listening to this thread since you started a new temporary session."
                        respond message_chatgpt, @listening[:threads][thread_ts], thread_ts: thread_ts
                        @listening[user_creator].delete(thread_ts)
                        @listening[:threads].delete(thread_ts)
                      end
                    end
                  end

                  @open_ai[user_creator] ||= {}
                  @open_ai[user_creator][:chat_gpt] ||= {}
                  @open_ai[user_creator][:chat_gpt][:sessions] ||= {}
                  @open_ai[user_creator][:chat_gpt][:sessions][session_name] ||= {}
                  @open_ai[user_creator][:chat_gpt][:sessions][session_name][:model] = model
                  @open_ai[user_creator][:chat_gpt][:sessions][session_name][:num_prompts] = 0
                end

                if message == "" and session_name == '' # ?? is called
                  @ai_gpt[user_creator][session_name] = []
                  respond "*ChatGPT*: Let's start a new temporary conversation. Ask me anything."
                  open_ai_chat_use_model(model, dont_save_stats: true) if model != ''
                else
                  react :speech_balloon
                  begin
                    urls_messages = []
                    get_openai_sessions(session_name, user_name: user_creator)
                    @ai_gpt[user_creator][session_name] = [] if delete_history
                    if @open_ai.key?(user_creator) and @open_ai[user_creator].key?(:chat_gpt) and @open_ai[user_creator][:chat_gpt].key?(:sessions) and
                      @open_ai[user_creator][:chat_gpt][:sessions].key?(session_name) and @open_ai[user_creator][:chat_gpt][:sessions][session_name].key?(:model)
                      if model == ''
                        model = @open_ai[user_creator][:chat_gpt][:sessions][session_name][:model].to_s 
                      else 
                        @open_ai[user_creator][:chat_gpt][:sessions][session_name][:model] = model
                      end
                    else
                      model = ''
                    end
                    model = @ai_open_ai[user_creator].chat_gpt.model if model.empty?
                    if message == ''
                      res = ''
                    else
                      if !files.nil? and files.size == 1
                        http = NiceHttp.new(host: "https://files.slack.com", headers: { "Authorization" => "Bearer #{config.token}" })
                        res = http.get(files[0].url_private_download)
                        message = "#{message}\n\n#{res.data}"
                      end
    
                      @open_ai[user_creator][:chat_gpt][:sessions][session_name][:num_prompts] += 1 

                      urls = message.scan(/!(https?:\/\/[\S]+)/).flatten
                      urls.uniq.each do |url|
                        begin
                            parsed_url = URI.parse(url)
                            domain = "#{parsed_url.scheme}://#{parsed_url.host}"
                            response = NiceHttp.new(domain).get(url)
                            html_doc = Nokogiri::HTML(response.body)
                            text = html_doc.text.gsub(/^\s*$/m, "")
                            urls_messages << "> #{url}: content extracted and added to prompt\n"
                        rescue Exception => e
                            text = "Error: #{e.message}"
                            urls_messages << "> #{url}: #{text}\n"
                        end
                        message.gsub!("!#{url}", url)
                        message+= "\n#{url} content:\n#{text}\n"
                      end

                      @ai_gpt[user_creator][session_name] << "Me> #{message}"
                      prompts = @ai_gpt[user_creator][session_name].join("\n\n")
                      prompts.gsub!(/^Me>\s*/,'')
                      prompts.gsub!(/^chatGPT>\s*/,'')
                      success, res = SlackSmartBot::AI::OpenAI.send_gpt_chat(@ai_open_ai[user_creator][:chat_gpt][:client], model, prompts, @ai_open_ai[user_creator].chat_gpt)
                      if success
                        @ai_gpt[user_creator][session_name] << "chatGPT> #{res}"
                      end
                    end
                    if session_name == ''
                      temp_session_name = @ai_gpt[user_creator][''].first[0..35].gsub('Me> ','')
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
                    update_openai_sessions(session_name, user_name: user_creator) unless session_name == ''
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
