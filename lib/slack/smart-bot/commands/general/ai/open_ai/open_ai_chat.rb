class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat(message, delete_history, type, model: '')
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
                  model: model
                }
              elsif type == :continue
                @open_ai[user.name][:chat_gpt][:sessions][session_name][:model] = model if model != ''
                respond "*GPT*: I just loaded *#{session_name}*."
              else
                @open_ai[user.name][:chat_gpt][:sessions][session_name][:model] = model if model != ''
                respond "*GPT*: You already have a session with that name.\nI just loaded *#{session_name}*."
              end          
              if Thread.current[:on_thread] and 
                  (Thread.current[:thread_ts] == Thread.current[:ts] or 
                    ( @open_ai[user.name][:chat_gpt][:sessions].key?(session_name) and
                      @open_ai[user.name][:chat_gpt][:sessions][session_name].key?(:thread_ts) and
                      @open_ai[user.name][:chat_gpt][:sessions][session_name][:thread_ts].include?(Thread.current[:thread_ts]) ) )
                @listening[user.name] ||= {}
                @listening[user.name][Thread.current[:thread_ts]] = Time.now
                @open_ai[user.name][:chat_gpt][:sessions][session_name][:thread_ts] ||= []
                @open_ai[user.name][:chat_gpt][:sessions][session_name][:thread_ts] << Thread.current[:thread_ts]
              else
                @active_chat_gpt_sessions[user.name][Thread.current[:dest]] = session_name
              end
            elsif type == :temporary and 
              (!@chat_gpt_collaborating.key?(user.name) or !@chat_gpt_collaborating[user.name].key?(Thread.current[:thread_ts]))
              if Thread.current[:on_thread] and 
                (Thread.current[:thread_ts] == Thread.current[:ts] or 
                  (@open_ai[user.name][:chat_gpt][:sessions].key?("") and @open_ai[user.name][:chat_gpt][:sessions][""][:thread_ts].include?(Thread.current[:thread_ts]) ))
                @listening[user.name] ||= {}
                @listening[user.name][Thread.current[:thread_ts]] = Time.now
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
                      respond "*GPT* Temporary session: _<#{temp_session_name}...>_ model: #{model}\n#{res.strip}"
                      if res.strip == ''
                        respond "It seems like GPT is not responding. Please try again later or use another model, as it might be overloaded."
                      end
                      #to avoid logging the prompt or the response
                      if config.encrypt
                        Thread.current[:encrypted] ||= []
                        Thread.current[:encrypted] << message
                      end
                    elsif res.strip == ''
                      respond "*GPT* Session _<#{session_name}>_ model: #{model}"
                      respond "It seems like GPT is not responding. Please try again later or use another model, as it might be overloaded." if message != ''
                    else
                      respond "*GPT* Session _<#{session_name}>_ model: #{model}\n#{res.strip}"
                    end
                    update_openai_sessions(session_name, user_name: user_creator) unless session_name == ''
                  rescue => exception
                    @logger.info exception
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
end
