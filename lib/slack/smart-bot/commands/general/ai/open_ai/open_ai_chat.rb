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

            if type == :add_collaborator
              save_stats(:open_ai_chat_add_collaborator)
              if session_name!='' and @active_chat_gpt_sessions[user.name].key?(Thread.current[:thread_ts])
                cname = message
                collaborator = @users.select{|u| u.id == cname or (u.key?(:enterprise_user) and u.enterprise_user.id == cname)}[-1]
                unless @open_ai[user.name][:chat_gpt][:sessions][session_name][:collaborators].include?(collaborator.name)
                  @open_ai[user.name][:chat_gpt][:sessions][session_name][:collaborators] << collaborator.name
                end
                @listening[collaborator.name] ||= {}
                @listening[collaborator.name][Thread.current[:thread_ts]] = Time.now
                @chat_gpt_collaborating[collaborator.name] ||= {}
                @chat_gpt_collaborating[collaborator.name][Thread.current[:thread_ts]] ||= { user_creator: user.name, session_name: session_name }
                respond "Now <@#{collaborator.name}> is a collaborator of this session only when on a thread.\nIn case you don't want to send a message as a prompt, just start the message with hyphen (-)."                
              else
                respond "You can add collaborators for the chatGPT session only when started on a thread and using a session name."
              end

            elsif type == :start or type == :continue
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

            elsif type == :delete
              #todo: add confirmation message
              save_stats(:open_ai_chat_delete_session)
              session_name = message
              @open_ai[user.name] ||= {}
              @open_ai[user.name][:chat_gpt] ||= {}
              @open_ai[user.name][:chat_gpt][:sessions] ||= {}
              if @open_ai[user.name][:chat_gpt][:sessions].key?(session_name)
                delete_threads = []
                @active_chat_gpt_sessions[user.name].each do |thread_ts, sname|
                  delete_threads << thread_ts if sname == session_name
                end
                delete_threads.each do |thread_ts|
                  @active_chat_gpt_sessions[user.name].delete(thread_ts)
                  @listening[user.name].delete(thread_ts)
                  @open_ai[user.name][:chat_gpt][:sessions][session_name][:collaborators].each do |collaborator|
                    @listening[collaborator].delete(thread_ts) if @listening.key?(collaborator)
                    @chat_gpt_collaborating[collaborator].delete(thread_ts) if @chat_gpt_collaborating.key?(collaborator)
                  end
                end

                @open_ai[user.name][:chat_gpt][:sessions].delete(session_name)

                update_openai_sessions(session_name)
                respond "*GPT*: Session *#{session_name}* deleted."
              else
                respond "*GPT*: You don't have a session with that name.\nCall `chatGPT list sessions` to see your saved sessions."
              end
            elsif type == :list
              save_stats(:open_ai_chat_list_sessions)
              if @open_ai.key?(user.name) and @open_ai[user.name].key?(:chat_gpt) and @open_ai[user.name][:chat_gpt].key?(:sessions)
                sessions = @open_ai[user.name][:chat_gpt][:sessions].keys.sort
                sessions.delete("")
                list_sessions = []
                sessions.each do |session_name|
                  session = @open_ai[user.name][:chat_gpt][:sessions][session_name]
                  list_sessions << "*`#{session_name}`*: started: *#{session.started}*, last activity: *#{session.last_activity}*#{", collaborators: *#{session.collaborators.join(', ')}*" unless !session.key?(:collaborators) or session.collaborators.empty?}."
                end
                respond "*GPT*: Your sessions are:\n#{list_sessions.join("\n")}"
              else
                respond "*GPT*: You don't have any session saved."
              end

            elsif type == :get
              save_stats(:open_ai_chat_get_prompts)
              session_name = message
              if @open_ai[user.name][:chat_gpt][:sessions].key?(session_name)
                get_openai_sessions(session_name)
                respond "*GPT*: Session *#{session_name}*."
                prompts = @ai_gpt[user.name][session_name].join("\n")
                prompts.gsub!(/^Me>\s*/,"\nMe> ")
                prompts.gsub!(/^chatGPT>\s*/,"\nchatGPT> ")
                if prompts.length > 3000
                  send_file(Thread.current[:dest], "", "prompts.txt", "", "text/plain", "text", content: prompts)
                else
                  if prompts.include?("`")
                    respond prompts
                  else
                    respond "```#{prompts}```"
                  end
                end
              else
                respond "*GPT*: You don't have a session with that name.\nCall `chatGPT list sessions` to see your saved sessions."
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

            unless type == :delete or type == :get or type == :list or type == :add_collaborator or 
              (type != :temporary and 
              (!@open_ai.key?(user_creator) or !@open_ai[user_creator].key?(:chat_gpt) or !@open_ai[user_creator][:chat_gpt].key?(:sessions) or
              !@open_ai[user_creator][:chat_gpt][:sessions].key?(session_name) or
              (@open_ai[user_creator][:chat_gpt][:sessions].key?(session_name) and !collaborator and user_creator!=user.name)))
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
                    model = @ai_open_ai[user_creator].gpt_model if model.nil? or model.empty?
                    if message == ''
                      res = ''
                    else
                      @ai_gpt[user_creator][session_name] << "Me> #{message}"#.force_encoding("UTF-8")
                      prompts = @ai_gpt[user_creator][session_name].join("\n\n")
                      prompts.gsub!(/^Me>\s*/,'')
                      prompts.gsub!(/^chatGPT>\s*/,'')
                      success, res = SlackSmartBot::AI::OpenAI.send_gpt_chat(@ai_open_ai[user_creator][:chat_gpt][:client], model, prompts)
                      if success
                        @ai_gpt[user_creator][session_name] << "chatGPT> #{res}"#.force_encoding("UTF-8")
                      end
                    end
                    if session_name == ''
                      temp_session_name = @ai_gpt[user_creator][''].first[0..35].gsub('Me> ','')
                      respond "*GPT* Temporary session: _<#{temp_session_name}...>_ model: #{model}\n#{res.strip}"
                    elsif res.strip == ''
                      respond "*GPT* Session _<#{session_name}>_ model: #{model}"
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
