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
            if @active_chat_gpt_sessions[user.name].key?(Thread.current[:thread_ts])
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
                respond "*GPT*: I just loaded *#{session_name}*.\nThere are *#{num_prompts} prompts* in this session.\nThis was the *last prompt* from the session:\n"
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
            elsif type == :temporary and 
              (!@chat_gpt_collaborating.key?(user.name) or !@chat_gpt_collaborating[user.name].key?(Thread.current[:thread_ts]))
              if Thread.current[:on_thread] and 
                (Thread.current[:thread_ts] == Thread.current[:ts] or 
                  (@open_ai[user.name][:chat_gpt][:sessions].key?("") and @open_ai[user.name][:chat_gpt][:sessions][""][:thread_ts].include?(Thread.current[:thread_ts]) ))
                @listening[user.name] ||= {}
                @listening[user.name][Thread.current[:thread_ts]] = Time.now
                @listening[:threads][Thread.current[:thread_ts]] = Thread.current[:dest]
                react :running if Thread.current[:thread_ts] == Thread.current[:ts]
                @open_ai[user.name] ||= {}
                @open_ai[user.name][:chat_gpt] ||= {}
                @open_ai[user.name][:chat_gpt][:sessions] ||= {}
                @open_ai[user.name][:chat_gpt][:sessions][""] ||= {}
                @open_ai[user.name][:chat_gpt][:sessions][""][:thread_ts] ||= []
                @open_ai[user.name][:chat_gpt][:sessions][""][:thread_ts].each do |thread_ts|
                  if thread_ts != Thread.current[:thread_ts] && @listening[:threads].key?(thread_ts)
                    unreact :running, thread_ts, channel: @listening[:threads][thread_ts]
                    message_chatgpt = "I'm sorry, but I'm no longer listening to this thread since you started a new temporary session."
                    respond message_chatgpt, @listening[:threads][thread_ts], thread_ts: thread_ts
                    @listening[user.name].delete(thread_ts)
                    @listening[:threads].delete(thread_ts)
                  end
                end
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
                if message == "" and session_name == '' # ?? is called
                  @ai_gpt[user_creator][session_name] = []
                  respond "*GPT*: Let's start a new temporary conversation. Ask me anything."
                else
                  react :speech_balloon
                  begin
                    get_openai_sessions(session_name, user_name: user_creator)
                    @ai_gpt[user_creator][session_name] = [] if delete_history
                    model = @open_ai[user_creator][:chat_gpt][:sessions][session_name][:model].to_s unless session_name == ''
                    model = @ai_open_ai[user_creator].chat_gpt.model if model.nil? or model.empty?
                    if message == ''
                      res = ''
                    else
                      if !files.nil? and files.size == 1
                        require "nice_http"
                        http = NiceHttp.new(host: "https://files.slack.com", headers: { "Authorization" => "Bearer #{config.token}" })
                        res = http.get(files[0].url_private_download)
                        message = "#{message}\n\n#{res.data}"
                      end
    
                      @open_ai[user_creator][:chat_gpt][:sessions][session_name][:num_prompts] += 1 if session_name != ''
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
                      respond "*GPT* Temporary session: _<#{temp_session_name.gsub("\n",' ').gsub("`",' ')}...>_ model: #{model}\n#{res.to_s.strip}"
                      if res.to_s.strip == ''
                        respond "It seems like GPT is not responding. Please try again later or use another model, as it might be overloaded."
                      end
                      #to avoid logging the prompt or the response
                      if config.encrypt
                        Thread.current[:encrypted] ||= []
                        Thread.current[:encrypted] << message
                      end
                    elsif res.to_s.strip == ''
                      respond "*GPT* Session _<#{session_name}>_ model: #{model}"
                      respond "It seems like GPT is not responding. Please try again later or use another model, as it might be overloaded." if message != ''
                    else
                      respond "*GPT* Session _<#{session_name}>_ model: #{model}\n#{res.to_s.strip}"
                    end
                    update_openai_sessions(session_name, user_name: user_creator) unless session_name == ''
                  rescue => exception
                    respond "*GPT*: Sorry, I'm having some problems. OpenAI probably is not available. Please try again later."
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
