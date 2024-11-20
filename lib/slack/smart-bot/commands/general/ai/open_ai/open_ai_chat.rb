class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat(message, delete_history, type, model: "", tag: "", description: "", files: [])
            message.strip!
            get_personal_settings()
            user = Thread.current[:user].dup
            user_name = user.name
            team_id = user.team_id
            team_id_user = Thread.current[:team_id_user]
            success = true
            if !defined?(@chat_gpt_default_model)
              #config.ai.open_ai.chat_gpt.model
              if config.key?(:ai) and config[:ai].key?(:open_ai) and config[:ai][:open_ai].key?(:chat_gpt) and
                 config[:ai][:open_ai][:chat_gpt].key?(:model)
                @chat_gpt_default_model = config[:ai][:open_ai][:chat_gpt][:model]
              else
                @chat_gpt_default_model = ""
              end
            end

            if model != "" and !@open_ai_models.include?(model)
              open_ai_models("", just_models: true) if @open_ai_models.empty?
              model_selected = @open_ai_models.select { |m| m.include?(model) }
              model = model_selected[0] if model_selected.size == 1
            end

            @active_chat_gpt_sessions[team_id_user] ||= {}
            if delete_history
              @active_chat_gpt_sessions[team_id_user][Thread.current[:dest]] = ""
              session_name = ""
            end
            if @active_chat_gpt_sessions[team_id_user].key?(Thread.current[:thread_ts]) and Thread.current[:thread_ts] != "" #added and Thread.current[:thread_ts]!='' for testing when SIMULATE==true and not in a thread
              session_name = @active_chat_gpt_sessions[team_id_user][Thread.current[:thread_ts]]
            elsif @active_chat_gpt_sessions[team_id_user].key?(Thread.current[:dest])
              if type == :temporary
                session_name = ""
                @active_chat_gpt_sessions[team_id_user][Thread.current[:dest]] = ""
              else
                #:continue_session
                session_name = @active_chat_gpt_sessions[team_id_user][Thread.current[:dest]]
              end
            else
              session_name = ""
              @active_chat_gpt_sessions[team_id_user][Thread.current[:dest]] = ""
            end
            if @open_ai.key?(team_id_user) and @open_ai[team_id_user].key?(:chat_gpt) and @open_ai[team_id_user][:chat_gpt].key?(:sessions) and
               @open_ai[team_id_user][:chat_gpt][:sessions].key?(session_name) and @open_ai[team_id_user][:chat_gpt][:sessions][session_name].key?(:collaborators)
              collaborators_saved = @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:collaborators]
            else
              collaborators_saved = []
            end

            if type == :start or type == :continue or type == :clean
              session_name = message

              @active_chat_gpt_sessions[team_id_user] ||= {}
              @active_chat_gpt_sessions[team_id_user][Thread.current[:thread_ts]] = session_name
              @active_chat_gpt_sessions[team_id_user][Thread.current[:dest]] = session_name
              message = ""
              get_openai_sessions(session_name)
              @open_ai[team_id_user] ||= {}
              @open_ai[team_id_user][:chat_gpt] ||= {}
              @open_ai[team_id_user][:chat_gpt][:sessions] ||= {}

              if !@open_ai[team_id_user][:chat_gpt][:sessions].key?(session_name) and
                 (type == :continue or type == :clean)
                respond "*ChatGPT*: I'm sorry, but I couldn't find a session named *#{session_name}*."
                return
              end

              if !@open_ai[team_id_user][:chat_gpt][:sessions].key?(session_name)
                @open_ai[team_id_user][:chat_gpt][:sessions][session_name] = {
                  team_creator: team_id,
                  user_creator: user_name,
                  started: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
                  last_activity: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
                  collaborators: [],
                  num_prompts: 0,
                  model: model,
                  copy_of_session: "",
                  copy_of_team: "",
                  copy_of_user: "",
                  users_copying: [],
                  temp_copies: 0,
                  own_temp_copies: 0,
                  public: false,
                  shared: [],
                  description: description,
                  tag: tag.downcase,
                  live_content: [],
                  static_content: [],
                  authorizations: {},
                }
              else # type == :continue or loading or clean
                @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:model] = model if model != ""
                num_prompts = @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:num_prompts]
                unless type == :clean
                  collaborators_txt = ""
                  if @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:collaborators].size > 0
                    collaborators = @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:collaborators].map do |team_user|
                      team_user.split("_")[1..-1].join("_")
                    end
                    collaborators_txt = ":busts_in_silhouette: Collaborators: `#{collaborators.join("`, `")}`\n"
                    @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:collaborators].each do |team_id_user_collaborator|
                      @chat_gpt_collaborating[team_id_user_collaborator] ||= {}
                      @chat_gpt_collaborating[team_id_user_collaborator][Thread.current[:thread_ts]] ||= { team_creator: team_id, user_creator: user.name, session_name: session_name }
                      @listening[team_id_user_collaborator] ||= {}
                      @listening[team_id_user_collaborator][Thread.current[:thread_ts]] = Time.now
                    end
                  end
                  if num_prompts > 0
                    respond "*ChatGPT*: I just loaded *#{session_name}*.\n#{collaborators_txt}There are *#{num_prompts} prompts* in this session.\nThis was the *last prompt* from the session:\n"
                  else
                    respond "*ChatGPT*: I just loaded *#{session_name}*.\n#{collaborators_txt}There are *no prompts* in this session."
                  end
                  content = @ai_gpt[team_id_user][session_name]
                  index_last_prompt = content.rindex { |c| c[:role] == "user" and c[:content].size == 1 and c[:content][0][:type] == "text" }
                  index_last_context = content.rindex { |c| c[:role] == "system" and c[:content].size == 1 and c[:content][0][:type] == "text" }
                  if index_last_context
                    last_context = "\n:robot_face: *User>* #{content[index_last_context][:content][0][:text]}\n"
                  else
                    last_context = ""
                  end
                  if !@open_ai[team_id_user][:chat_gpt][:sessions][session_name][:live_content].nil? and
                     @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:live_content].size > 0
                    live_content = "\n:globe_with_meridians: *Live content*:\n\t\t - `#{@open_ai[team_id_user][:chat_gpt][:sessions][session_name][:live_content].join("`\n\t\t - `")}`"
                  else
                    live_content = ""
                  end
                  if !@open_ai[team_id_user][:chat_gpt][:sessions][session_name][:static_content].nil? and
                     @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:static_content].size > 0
                    static_content = "\n:pushpin: *Static content*:\n\t\t - `#{@open_ai[team_id_user][:chat_gpt][:sessions][session_name][:static_content].join("`\n\t\t - `")}`"
                    if Thread.current[:dest][0] != "D"
                      @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:static_content].each do |cont|
                        channel_hist = cont.scan(/\AHistory of <#(\w+)>\Z/im).flatten[0]
                        if channel_hist != Thread.current[:dest]
                          respond ":information_source: I'm sorry this session is trying to load the history of <##{channel_hist}>, but you can only load the history of the channel where you are currently talking or in a DM with me."
                          return
                        end
                      end
                    end
                  else
                    static_content = ""
                  end

                  #authorizations
                  if !@open_ai[team_id_user][:chat_gpt][:sessions][session_name][:authorizations].nil? and
                     @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:authorizations].size > 0
                    auth = "\n:lock: *Authorizations:*\n"
                    @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:authorizations].each do |host, header|
                      auth += "\t\t - `#{host}`: `#{header.keys.join("`, `")}`\n"
                    end
                  else
                    auth = ""
                  end
                  if index_last_prompt.nil?
                    respond "#{last_context}No prompts found.\n#{live_content}#{static_content}#{auth}" unless delete_history
                  else
                    last_prompt = ""
                    content[index_last_prompt..-1].each do |c|
                      if c[:role] == "user" and c[:content].size == 1 and c[:content][0][:type] == "text"
                        if c[:content][0].key?(:clean_text)
                          if @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:static_content].nil? or
                             !@open_ai[team_id_user][:chat_gpt][:sessions][session_name][:static_content].include?(c[:content][0][:clean_text])
                            last_prompt += ":runner: *User>* #{transform_to_slack_markdown(c[:content][0][:clean_text])}\n"
                          end
                        else
                          last_prompt += ":runner: *User>* #{transform_to_slack_markdown(c[:content][0][:text])}\n"
                        end
                      elsif c[:role] == "user" and c[:content].size == 1 and c[:content][0][:type] != "text"
                        last_prompt += ":runner: *User>* Attached file type #{c[:content][0][:type]}\n"
                      elsif c[:role] == "assistant" and c[:content].size == 1 and c[:content][0][:type] == "text"
                        last_prompt += ":speech_balloon: *ChatGPT>* #{transform_to_slack_markdown(c[:content][0][:text])}\n"
                      end
                    end
                    respond last_prompt + last_context + live_content + static_content + auth
                  end
                end
              end
              if Thread.current[:on_thread] and
                 (Thread.current[:thread_ts] == Thread.current[:ts] or
                  (@open_ai[team_id_user][:chat_gpt][:sessions].key?(session_name) and
                   @open_ai[team_id_user][:chat_gpt][:sessions][session_name].key?(:thread_ts) and
                   @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:thread_ts].include?(Thread.current[:thread_ts])))
                react :running, Thread.current[:thread_ts]
                @listening[team_id_user] ||= {}
                @listening[team_id_user][Thread.current[:thread_ts]] = Time.now
                @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:thread_ts] ||= []

                @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:thread_ts] << Thread.current[:thread_ts]
                @listening[:threads][Thread.current[:thread_ts]] = Thread.current[:dest]
              else
                @active_chat_gpt_sessions[team_id_user][Thread.current[:dest]] = session_name
              end
              @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:description] = description if description != ""
              @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:tag] = tag.downcase if tag != ""
              open_ai_chat_use_model(model, dont_save_stats: true) if model != ""
            elsif type == :temporary and
                  (!@chat_gpt_collaborating.key?(team_id_user) or !@chat_gpt_collaborating[team_id_user].key?(Thread.current[:thread_ts]))
              @open_ai[team_id_user] ||= {}
              @open_ai[team_id_user][:chat_gpt] ||= {}
              @open_ai[team_id_user][:chat_gpt][:sessions] ||= {}

              if Thread.current[:on_thread] and
                 (Thread.current[:thread_ts] == Thread.current[:ts] or
                  (@open_ai[team_id_user][:chat_gpt][:sessions].key?("") and @open_ai[team_id_user][:chat_gpt][:sessions][""].key?(:thread_ts) and
                   @open_ai[team_id_user][:chat_gpt][:sessions][""][:thread_ts].include?(Thread.current[:thread_ts])))
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
            if delete_history and type != :clean and @open_ai.key?(team_id_user) and @open_ai[team_id_user].key?(:chat_gpt) and @open_ai[team_id_user][:chat_gpt].key?(:sessions) and
               @open_ai[team_id_user][:chat_gpt][:sessions].key?(session_name)
              if session_name == "" and type == :temporary
                @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:collaborators] = []
                @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:num_prompts] = 0
                @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:copy_of_session] = ""
                @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:copy_of_team] = ""
                @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:copy_of_user] = ""
              end
              @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:live_content] = []
              @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:static_content] = []
              @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:authorizations] = {}
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
                    (@open_ai[team_id_user_creator][:chat_gpt][:sessions].key?(session_name) and !collaborator and user_creator != user.name))
              subtype = ""
              if type == :clean
                save_stats(:open_ai_chat_clean_session)
              elsif message.match?(/\A\s*set\s+context\s+(.+)\s*\Z/i)
                subtype = :set_context
                save_stats(:open_ai_chat_set_context)
              elsif message.match(/\A\s*add\s+live\s+(resource|content|feed|doc)s?\s+(.+)\s*\Z/im)
                subtype = :add_live_content
                save_stats(:open_ai_chat_add_live_content)
              elsif message.match(/\A\s*add\s+(static\s+)?(resource|content|doc)s?\s+(.+)\s*\Z/im)
                subtype = :add_static_content
                save_stats(:open_ai_chat_add_static_content)
              elsif message.match(/\A\s*add\s+history\s+(channel\s+)?<#(\w+)\|.*>\s*\Z/im)
                subtype = :add_history_channel
                save_stats(:open_ai_chat_add_history_channel)
              elsif message.match(/\A\s*delete\s+live\s+(resource|content|feed|doc)s?\s+(.+)\s*\Z/im)
                subtype = :delete_live_content
                save_stats(:open_ai_chat_delete_live_content)
              elsif message.match(/\A\s*delete\s+(static\s+)?(resource|content|doc)s?\s+(.+)\s*\Z/im)
                subtype = :delete_static_content
                save_stats(:open_ai_chat_delete_static_content)
              elsif message.match(/\A\s*delete\s+history\s+(channel\s+)?<#(\w+)\|.*>\s*\Z/im)
                subtype = :delete_history_channel
                save_stats(:open_ai_chat_delete_history_channel)
              elsif message.match(/\A\s*add\s+authorization\s+([^\s]+)\s+([^\s]+)\s+(.+)\s*\Z/im)
                subtype = :add_authorization
                save_stats(:open_ai_chat_add_authorization)
              elsif message.match(/\A\s*delete\s+authorization\s+([^\s]+)\s+([^\s]+)\s*\Z/im)
                subtype = :delete_authorization
                save_stats(:open_ai_chat_delete_authorization)
              else
                save_stats(__method__)
              end
              @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:last_activity] = Time.now.strftime("%Y-%m-%d %H:%M:%S") unless session_name == ""
              @ai_open_ai, message_connect = SlackSmartBot::AI::OpenAI.connect(@ai_open_ai, config, @personal_settings, reconnect: delete_history, service: :chat_gpt)

              respond message_connect if message_connect
              if !@ai_open_ai[team_id_user_creator].nil? and !@ai_open_ai[team_id_user_creator][:chat_gpt][:client].nil?
                @ai_gpt[team_id_user_creator] ||= {}
                @ai_gpt[team_id_user_creator][session_name] ||= []
                if delete_history or !@open_ai.key?(team_id_user_creator) or !@open_ai[team_id_user_creator].key?(:chat_gpt) or
                   !@open_ai[team_id_user_creator][:chat_gpt].key?(:sessions) or
                   !@open_ai[team_id_user_creator][:chat_gpt][:sessions].key?(session_name) or
                   !@open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name].key?(:model) or
                   !@open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name].key?(:num_prompts)
                  if delete_history and session_name == "" && @open_ai.key?(team_id_user_creator) && @open_ai[team_id_user_creator].key?(:chat_gpt) &&
                                        @open_ai[team_id_user_creator][:chat_gpt].key?(:sessions) && @open_ai[team_id_user_creator][:chat_gpt][:sessions].key?("") &&
                                        @open_ai[team_id_user_creator][:chat_gpt][:sessions][""].key?(:thread_ts)
                    @open_ai[team_id_user_creator][:chat_gpt][:sessions][""][:thread_ts].each do |thread_ts|
                      if thread_ts != Thread.current[:thread_ts] && @listening[:threads].key?(thread_ts)
                        unreact :running, thread_ts, channel: @listening[:threads][thread_ts]
                        message_chatgpt = ":information_source: I'm sorry, but I'm no longer listening to this thread since you started a new temporary session."
                        respond message_chatgpt, @listening[:threads][thread_ts], thread_ts: thread_ts
                        @listening[team_id_user_creator].delete(thread_ts)
                        @listening[:threads].delete(thread_ts)
                        collaborators_saved.each do |team_id_user_collaborator|
                          if @listening.key?(team_id_user_collaborator)
                            @listening[team_id_user_collaborator].delete(thread_ts)
                          end
                          if @chat_gpt_collaborating.key?(team_id_user_collaborator) && @chat_gpt_collaborating[team_id_user_collaborator].key?(thread_ts)
                            @chat_gpt_collaborating[team_id_user_collaborator].delete(thread_ts)
                          end
                        end
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

                if message == "" and session_name == "" # ?? is called
                  @ai_gpt[team_id_user_creator][session_name] = []
                  respond "*ChatGPT*: Let's start a new temporary conversation. Ask me anything."
                  open_ai_chat_use_model(model, dont_save_stats: true) if model != ""
                  @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:live_content] = []
                  @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:static_content] = []
                  @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:authorizations] = {}
                else
                  treated = false
                  react :speech_balloon
                  begin
                    urls_messages = []
                    get_openai_sessions(session_name, team_id: team_creator, user_name: user_creator)
                    if delete_history
                      prompts = []
                      if type == :temporary
                        @ai_gpt[team_id_user_creator][session_name] = []
                      else
                        #remove all prompts that are not static content or context
                        @ai_gpt[team_id_user_creator][session_name].each do |c|
                          if (c[:role] == "user" and c[:content].size == 1 and c[:content][0][:type] == "text" and c[:content][0].key?(:clean_text) and
                              @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:static_content].include?(c[:content][0][:clean_text])) or
                             c[:role] == "system"
                            prompts << c
                          end
                        end
                      end
                      @ai_gpt[team_id_user_creator][session_name] = prompts
                    end

                    if @open_ai.key?(team_id_user_creator) and @open_ai[team_id_user_creator].key?(:chat_gpt) and @open_ai[team_id_user_creator][:chat_gpt].key?(:sessions) and
                       @open_ai[team_id_user_creator][:chat_gpt][:sessions].key?(session_name) and @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name].key?(:model)
                      if model == ""
                        model = @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:model].to_s
                      else
                        @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:model] = model
                      end
                    else
                      model = ""
                    end
                    model = @ai_open_ai[team_id_user_creator].chat_gpt.model if model.empty?
                    max_num_tokens = 8000 #default in case no model is found
                    @open_ai_model_info ||= {}
                    if !@open_ai_model_info.key?(model)
                      ai_models_conn, message_conn = SlackSmartBot::AI::OpenAI.connect({}, config, {}, service: :models)
                      models = ai_models_conn[team_id_user_creator].models
                      unless models.nil? or models.client.nil? or message_conn.to_s != ""
                        @open_ai_model_info[model] ||= SlackSmartBot::AI::OpenAI.models(models.client, models, model, return_response: true)
                      end
                    end
                    if @open_ai_model_info.key?(model) and @open_ai_model_info[model].key?(:max_input_tokens)
                      max_num_tokens = @open_ai_model_info[model][:max_input_tokens].to_i
                    elsif @open_ai_model_info.key?(model) and @open_ai_model_info[model].key?(:max_tokens)
                      max_num_tokens = @open_ai_model_info[model][:max_tokens].to_i
                    end

                    if message.match?(/\A\s*resend\s+prompt\s*\z/i) and !@ai_gpt[team_id_user_creator][session_name].empty?
                      files_attached = []
                      system_prompt = @ai_gpt[team_id_user_creator][session_name].pop if @ai_gpt[team_id_user_creator][session_name].last[:role] == "system"
                      @ai_gpt[team_id_user_creator][session_name].pop if @ai_gpt[team_id_user_creator][session_name].last[:role] == "assistant"
                      while @ai_gpt[team_id_user_creator][session_name].last[:role] == "user" and
                            @ai_gpt[team_id_user_creator][session_name].last[:content].first[:type] == "image_url"
                        files_attached << @ai_gpt[team_id_user_creator][session_name].last[:content].first
                        @ai_gpt[team_id_user_creator][session_name].pop
                      end
                      if @ai_gpt[team_id_user_creator][session_name].last[:role] == "user" and
                         @ai_gpt[team_id_user_creator][session_name].last[:content].first[:type] == "text"
                        last_prompt = @ai_gpt[team_id_user_creator][session_name].pop
                        if last_prompt[:content].first.key?(:clean_text) and
                           (@open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:static_content].nil? or
                            !@open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:static_content].include?(last_prompt[:content].first[:clean_text]))
                          message = last_prompt[:content].first[:clean_text]
                        else
                          message = last_prompt[:content].first[:text]
                        end
                        respond ":information_source: Last ChatGPT response was removed from history.\nPrompt resent: `#{message}`"
                      end
                    elsif subtype == :set_context
                      context = message.match(/\A\s*set\s+context\s+(.+)\s*\Z/i)[1]
                      @ai_gpt[team_id_user_creator][session_name] << { role: "system", content: [{ type: "text", text: context }] }
                      respond ":information_source: Context set to: `#{context}`"
                      treated = true
                    elsif message.match(/\A\s*add\s+live\s+(resource|content|feed|doc)s?\s+(.+)\s*\Z/im)
                      opts = $2.to_s
                      opts.gsub!("!http", "http")
                      urls = opts.scan(/https?:\/\/[^\s\/$.?#].[^\s]*/)
                      @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:live_content] ||= []
                      copy_of_user = @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:copy_of_user]
                      if copy_of_user.to_s != "" and copy_of_user != user_name
                        #check if host of url is in authorizations of the user orig of the session
                        team_id_user_orig = @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:copy_of_team] + "_" +
                                            @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:copy_of_user]
                        copy_of_session = @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:copy_of_session]
                        auth_user_orig = @open_ai[team_id_user_orig][:chat_gpt][:sessions][copy_of_session][:authorizations]
                        not_allowed = []
                        #if the host is on auth of the user orig, then it is not allwed for other users to add it
                        urls.each do |url|
                          host = URI.parse(url).host
                          if auth_user_orig.key?(host)
                            not_allowed << url
                          end
                        end
                        if not_allowed.size > 0
                          respond ":warning: You are not allowed to add the following URLs because they are part of the authorizations of the user that created the session:\n\t\t - `#{not_allowed.join("`\n\t\t - `")}`"
                          urls -= not_allowed
                        end
                      end
                      if urls.size > 0
                        urls.each do |url|
                          @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:live_content] << url
                        end
                        @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:live_content].uniq!
                        respond ":globe_with_meridians: Live content added:\n\t\t - `#{urls.join("`\n\t\t - `")}`\nEvery time you send a new prompt, it will use the latest version of the resource.\nCall `delete live content URL1 URL99` to remove them."
                      end
                      treated = true
                    elsif message.match(/\A\s*add\s+(static\s+)?(resource|content|doc)s?\s+(.+)\s*\Z/im)
                      opts = $3.to_s
                      opts.gsub!("!http", "http")
                      urls = opts.scan(/https?:\/\/[^\s\/$.?#].[^\s]*/)
                      @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:static_content] ||= []
                      copy_of_user = @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:copy_of_user]
                      if copy_of_user.to_s != "" and copy_of_user != user_name
                        #check if host of url is in authorizations of the user orig of the session
                        team_id_user_orig = @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:copy_of_team] + "_" +
                                            @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:copy_of_user]
                        copy_of_session = @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:copy_of_session]
                        auth_user_orig = @open_ai[team_id_user_orig][:chat_gpt][:sessions][copy_of_session][:authorizations]
                        not_allowed = []
                        #if the host is on auth of the user orig, then it is not allwed for other users to add it
                        urls.each do |url|
                          host = URI.parse(url).host
                          if auth_user_orig.key?(host)
                            not_allowed << url
                          end
                        end
                        if not_allowed.size > 0
                          respond ":warning: You are not allowed to add the following URLs because they are part of the authorizations of the user that created the session:\n\t\t - `#{not_allowed.join("`\n\t\t - `")}`"
                          urls -= not_allowed
                        end
                      end
                      if urls.size > 0
                        authorizations = get_authorizations(session_name, team_id_user_creator)
                        threads = []
                        urls.uniq.each do |url|
                          @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:static_content] << url
                          threads << Thread.new do
                            text, url_message = download_http_content(url, authorizations, team_id_user_creator, session_name)
                            @ai_gpt[team_id_user_creator][session_name] << { role: "user", content: [{ type: "text", text: text, clean_text: url }] }
                          end
                        end
                        threads.each(&:join)

                        @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:static_content].uniq!
                        update_openai_sessions(session_name, team_id: team_creator, user_name: user_creator) unless session_name == ""
                        respond ":pushpin: Static content added:\n\t\t - `#{urls.join("`\n\t\t - `")}`\nCall `delete static content URL1 URL99` to remove them."
                      end
                      treated = true
                    elsif message.match(/\A\s*add\s+history\s+(channel\s+)?<#(\w+)\|.*>\s*\Z/im)
                      channel_history = $2.to_s
                      #check if the user is on the channel or on a DM with the bot
                      if Thread.current[:dest][0] == "D" or Thread.current[:dest] == channel_history
                        members_channel_history = get_channel_members(channel_history)
                        #check if SmartBot and The granular smartbot are members of the channel
                        if members_channel_history.include?(config.nick_id) and members_channel_history.include?(config.nick_id_granular)
                          if Thread.current[:dest][0] == "D"
                            #Check if the user is a member of the Channel
                            if !members_channel_history.include?(user.id)
                              respond ":warning: You are not a member of the channel <##{channel_history}>."
                            end
                          end
                          #get the history of the channel
                          @history_still_running ||= false
                          if @history_still_running
                            respond "Due to Slack API rate limit, when getting history of a channel this command is limited. Waiting for other command to finish."
                            num_times = 0
                            while @history_still_running and num_times < 30
                              num_times += 1
                              sleep 1
                            end
                            if @history_still_running
                              respond "Sorry, Another command is still running after 30 seconds. Please try again later."
                            end
                          end
                          unless @history_still_running
                            @history_still_running = true
                            #from 6 months ago
                            from = Time.now - 60 * 60 * 24 * 180
                            to = Time.now
                            respond "Adding the history of the channel from #{from.strftime("%Y-%m-%d")}. Take in consideration that this could take a while."
                            hist = []
                            num_times = 0
                            while hist.empty? and num_times < 6
                              client_granular.conversations_history(channel: channel_history, limit: 1000, oldest: from.to_f, latest: to.to_f) do |response|
                                hist << response.messages
                              end
                              hist.flatten!
                              num_times += 1
                              if hist.empty?
                                if num_times == 1
                                  respond "It seems like the history of the channel is empty. It could be the Slack API rate limit. I'll try again for one minute."
                                end
                                sleep 10
                              end
                            end
                            messages = {} # store the messages by year/month
                            act_users = {}
                            act_threads = {}
                            #from the past 6 months
                            hist.each do |hist_message|
                              if Time.at(hist_message.ts.to_f) >= from
                                year_month = Time.at(hist_message.ts.to_f).strftime("%Y-%m")
                                messages[year_month] ||= []
                                if hist_message.key?("thread_ts")
                                  thread_ts_message = hist_message.thread_ts
                                  replies = client_granular.conversations_replies(channel: channel_history, ts: thread_ts_message) #jal, latest: last_msg.ts)
                                  sleep 0.5 #to avoid rate limit Tier 3 (50 requests per minute)
                                  messages_replies = ["Thread Started about last message:"]
                                  act_threads[hist_message.ts] = replies.messages.size
                                  replies.messages.each_with_index do |msgrepl, i|
                                    act_users[msgrepl.user] ||= 0
                                    act_users[msgrepl.user] += 1
                                    messages_replies << "<@#{msgrepl.user}> (#{Time.at(msgrepl.ts.to_f)}) wrote:> #{msgrepl.text}" if i > 0
                                  end
                                  messages_replies << "Thread ended."
                                  messages[year_month] += messages_replies.reverse # the order on repls is from older to newer
                                end
                                act_users[hist_message.user] ||= 0
                                act_users[hist_message.user] += 1
                                url_to_message = "https://#{client.team.domain}.slack.com/archives/#{channel_history}/#{hist_message.ts}"
                                messages[year_month] << "<@#{hist_message.user}> (#{Time.at(hist_message.ts.to_f)}) (link to the message: #{url_to_message}) wrote:> #{hist_message.text}"
                              end
                            end
                            @history_still_running = false
                            messages.each do |year_month, msgs|
                              messages[year_month] = msgs.reverse # the order on history is from newer to older
                            end
                            if messages.empty?
                              #last 6 months
                              message_history = ":warning: No messages found on the channel <##{channel_history}> from the past 6 months."
                              message_history += "\n\nIt could be the Slack API rate limit. Please try again in a while."
                              respond message_history
                            else
                              #sort by year/month from older to newer
                              messages = messages.sort_by { |k, v| k }.to_h
                              #check num_tokens don't exceed max_num_tokens
                              #remove messages if it exceeds from the oldest to the newest
                              num_tokens = 0
                              prompts_check = @ai_gpt[team_id_user_creator][session_name].deep_copy
                              prompts_check_text = prompts_check.map { |c| c[:content].map { |cont| cont[:text] }.join("\n") }.join("\n")
                              enc = Tiktoken.encoding_for_model("gpt-4") #jal todo: fixed value since version 0.0.8 and 0.0.9 failed to install on SmartBot VM. Revert when fixed.
                              text_to_check = nil
                              num_tokens = 0
                              removed_months = []
                              while text_to_check.nil? or num_tokens > (max_num_tokens - 1000)
                                if num_tokens > (max_num_tokens - 1000)
                                  removed_months << messages.keys.first
                                  messages.shift
                                end
                                text_to_check = messages.values.flatten.join("\n") + prompts_check_text
                                num_tokens = enc.encode(text_to_check.to_s).length
                              end
                              if messages.empty?
                                message_history = ":warning: The history of the channel exceeds the limit of tokens allowed."
                                if removed_months.size > 0
                                  message_history += "\n\n:The following months were removed because the total number of ChatGPT tokens exceeded the limit of the model:\n\t\t - `#{removed_months.join("`\n\t\t - `")}`"
                                end
                              else
                                history_text = "This is the history of conversations on the Slack channel <##{channel_history}>:\n\n#{messages.values.flatten.join("\n")}"
                                @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:static_content] ||= []
                                @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:static_content] << "History of <##{channel_history}>"
                                @ai_gpt[team_id_user_creator][session_name] << { role: "user", content: [{ type: "text", text: history_text, clean_text: "History of <##{channel_history}>" }] }
                                @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:static_content].uniq!
                                update_openai_sessions(session_name, team_id: team_creator, user_name: user_creator) unless session_name == ""
                                message_history = ":scroll: History of the channel <##{channel_history}> from the past 6 months added to the session.\nCall `delete history <##{channel_history}>` to delete it."
                                if removed_months.size > 0
                                  message_history += "\n\n:warning: The following months were removed because the total number of tokens exceeded the limit:\n\t\t - `#{removed_months.join("`\n\t\t - `")}`"
                                end
                                message_history += "\n\nThe history of that channel will be used as part of the prompts for the next responses."
                                # specify month and year
                                message_history += "\n\nThe first message added is from #{messages.keys.first}."
                                message_history += "\n\t\tTotal number of messages added: #{messages.values.flatten.size - act_threads.size}."
                                message_history += "\n\t\tNumber of threads added: #{act_threads.size}."
                                message_history += "\n\t\tNumber of messages on threads added: #{act_threads.values.sum}." unless removed_months.size > 0
                                respond message_history
                              end
                            end
                          end
                        else
                          respond ":warning: <@#{config.nick_id}> and <@#{config.nick_id_granular}> need to be members of the channel <##{channel_history}> to be able to add its history. Please add them to the channel and try again."
                        end
                      else
                        respond ":warning: You can only add the history of a Slack channel where you are or on a DM with me."
                      end

                      treated = true
                    elsif message.match(/\A\s*delete\s+live\s+(resource|content|feed|doc)s?\s+(.+)\s*\Z/im)
                      opts = $2.to_s
                      opts.gsub!("!http", "http")
                      urls = opts.scan(/https?:\/\/[^\s\/$.?#].[^\s]*/)
                      @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:live_content] ||= []
                      not_found = []
                      urls.each do |url|
                        unless @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:live_content].delete(url)
                          not_found << url
                        end
                      end
                      message_live_content = []
                      message_live_content << "Live content removed: `#{(urls - not_found).join("`, `")}`." if (urls - not_found).size > 0
                      message_live_content << "Not found: `#{not_found.join("`, `")}`." if not_found.size > 0
                      respond ":globe_with_meridians: #{message_live_content.join("\n")}"
                      treated = true
                    elsif message.match(/\A\s*delete\s+(static\s+)?(resource|content|doc)s?\s+(.+)\s*\Z/im)
                      opts = $3.to_s
                      opts.gsub!("!http", "http")
                      urls = opts.scan(/https?:\/\/[^\s\/$.?#].[^\s]*/)
                      @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:static_content] ||= []
                      not_found = []
                      urls.each do |url|
                        unless @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:static_content].delete(url)
                          not_found << url
                        end
                        @ai_gpt[team_id_user_creator][session_name].each do |prompt|
                          prompt[:content].each do |content|
                            if content[:type] == "text" and content[:clean_text] == url
                              @ai_gpt[team_id_user_creator][session_name].delete(prompt)
                            end
                          end
                        end
                      end
                      update_openai_sessions(session_name, team_id: team_creator, user_name: user_creator) unless session_name == ""
                      message_static_content = []
                      message_static_content << "Static content removed: `#{(urls - not_found).join("`, `")}`." if (urls - not_found).size > 0
                      message_static_content << "Not found: `#{not_found.join("`, `")}`." if not_found.size > 0
                      respond ":pushpin: #{message_static_content.join("\n")}"
                      treated = true
                    elsif message.match(/\A\s*delete\s+history\s+(channel\s+)?<#(\w+)\|.*>\s*\Z/im)
                      channel_history = $2.to_s
                      @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:static_content] ||= []
                      @ai_gpt[team_id_user_creator][session_name].each do |prompt|
                        prompt[:content].each do |content|
                          if content[:type] == "text" and content[:clean_text] == "History of <##{channel_history}>"
                            @ai_gpt[team_id_user_creator][session_name].delete(prompt)
                          end
                        end
                      end
                      @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:static_content].delete_if { |url| url == "History of <##{channel_history}>" }
                      update_openai_sessions(session_name, team_id: team_creator, user_name: user_creator) unless session_name == ""
                      respond ":scroll: History of the channel <##{channel_history}> removed from the session."
                      treated = true

                      #add authorization HOST HEADER VALUE
                      #for example: add authorization api.example.com Authorization Bearer 123456
                    elsif message.match(/\A\s*add\s+authorization\s+([^\s]+)\s+([^\s]+)\s+(.+)\s*\Z/im)
                      host = $1.to_s
                      header = $2.to_s
                      value = $3.to_s
                      #remove http:// or https:// from host
                      host.gsub!(/\Ahttps?:\/\//, "")
                      @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:authorizations] ||= {}
                      @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:authorizations][host] ||= {}
                      @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:authorizations][host][header] = value
                      message_sec = [":key: Authorization header added: `#{header}` for host `#{host}`."]
                      message_sec << "Call `delete authorization HOST HEADER` to remove it."
                      message_sec << "This authorization will be used only for this session."
                      unless type == :temporary
                        message_sec << "If you share this session, they will be able to use the authorization but will not be able to see the authorization value."
                      end
                      respond message_sec.join("\n")
                      treated = true
                      #delete authorization HOST HEADER
                      #for example: delete authorization api.example.com Authorization
                    elsif message.match(/\A\s*delete\s+authorization\s+([^\s]+)\s+([^\s]+)\s*\Z/im)
                      host = $1.to_s
                      header = $2.to_s
                      host.gsub!(/\Ahttps?:\/\//, "")
                      if @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:authorizations].nil? or
                         @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:authorizations][host].nil? or
                         @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:authorizations][host][header].nil?
                        respond ":key: Authorization header not found: `#{header}` for host `#{host}`."
                      else
                        @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:authorizations] ||= {}
                        @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:authorizations][host] ||= {}
                        @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:authorizations][host].delete(header)
                        respond ":key: Authorization header deleted: `#{header}` for host `#{host}`."
                      end
                      treated = true
                    end
                    unless treated
                      num_folder_docs = 0
                      if message == ""
                        res = ""
                        prompts ||= []
                      else
                        restricted = false
                        files_attached ||= []
                        if !files.nil?
                          files.each do |file|
                            http2 = NiceHttp.new(host: "https://files.slack.com", headers: { "Authorization" => "Bearer #{config.token}" })
                            res = http2.get(file.url_private_download)
                            #identify the type of file. In case of image identify the type and encode it to base64
                            if res[:'content-type'].to_s.include?("image")
                              require "base64"
                              image_type = res[:'content-type'].split("/")[1]
                              data = "data:image/#{image_type};base64,#{Base64.strict_encode64(res.body)}"
                              files_attached << { type: "image_url", image_url: { url: data } }
                            else
                              message = "#{message}\n\n#{res.data}"
                            end
                            http2.close
                          end
                        end

                        @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:num_prompts] += 1
                        urls = message.scan(/!(https?:\/\/[\S]+)/).flatten
                        if urls.size > 0 and @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:copy_of_user] != user_name
                          #check if host of url is in authorizations of the user orig of the session
                          team_id_user_orig = @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:copy_of_team] + "_" +
                                              @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:copy_of_user]
                          copy_of_session = @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:copy_of_session]
                          if @open_ai.key?(team_id_user_orig) and @open_ai[team_id_user_orig].key?(:chat_gpt) and
                             @open_ai[team_id_user_orig][:chat_gpt].key?(:sessions) and @open_ai[team_id_user_orig][:chat_gpt][:sessions].key?(copy_of_session) and
                             !@open_ai[team_id_user_orig][:chat_gpt][:sessions][copy_of_session].key?(:authorizations)
                            auth_user_orig = @open_ai[team_id_user_orig][:chat_gpt][:sessions][copy_of_session][:authorizations]
                          else
                            auth_user_orig = {}
                          end
                          not_allowed = []
                          #if the host is on auth of the user orig, then it is not allwed for other users to add it
                          urls.each do |url|
                            host = URI.parse(url).host
                            if auth_user_orig.key?(host)
                              not_allowed << url
                            end
                          end
                          if not_allowed.size > 0
                            respond ":warning: You are not allowed to add the following URLs because they are part of the authorizations of the user that created the session:\n\t\t - `#{not_allowed.join("`\n\t\t - `")}`"
                            urls -= not_allowed
                          end
                        end

                        if !@open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:live_content].nil?
                          urls += @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:live_content]
                        end
                        #get a copy of message
                        clean_message = message.dup
                        authorizations = get_authorizations(session_name, team_id_user_creator)
                        #download the content of the urls simultaneously on threads
                        threads = []
                        texts = []
                        urls.uniq.each do |url|
                          threads << Thread.new do
                            text, url_message = download_http_content(url, authorizations, team_id_user_creator, session_name)
                            urls_messages << url_message if url_message != ""
                            texts << text
                          end
                        end
                        threads.each(&:join)
                        urls.uniq.each do |url|
                          message.gsub!("!#{url}", "")
                        end
                        texts.each do |text|
                          message += "\n #{text}\n"
                        end

                        if urls.empty?
                          @ai_gpt[team_id_user_creator][session_name] << { role: "user", content: [{ type: "text", text: message }] }
                        else
                          @ai_gpt[team_id_user_creator][session_name] << { role: "user", content: [{ type: "text", text: message, clean_text: clean_message }] }
                        end
                        files_attached.each do |file|
                          @ai_gpt[team_id_user_creator][session_name] << { role: "user", content: [file] }
                        end
                        prompts = @ai_gpt[team_id_user_creator][session_name].deep_copy
                        prompts.each do |prompt|
                          prompt[:content].each do |content|
                            content.delete(:clean_text)
                          end
                        end
                        if @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:copy_of_session] == ""
                          path_to_session_folder = "#{config.path}/openai/#{team_creator}/#{user_creator}/#{session_name}"
                          term_to_avoid = session_name
                        else
                          copy_of_team = @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:copy_of_team]
                          copy_of_user = @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:copy_of_user]
                          term_to_avoid = @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:copy_of_session]
                          path_to_session_folder = "#{config.path}/openai/#{copy_of_team}/#{copy_of_user}/"
                          path_to_session_folder += @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:copy_of_session].to_s
                        end

                        if Dir.exist?(path_to_session_folder)
                          #read the content of chatgpt_prompts.json and add it to the prompts at the beginning
                          if !File.exist?("#{path_to_session_folder}/chatgpt_prompts.json")
                            # Get the content of all files in all folders and subfolders and add it to the chatgpt_prompts.json file
                            docs_folder_prompts = []
                            #enc = Tiktoken.encoding_for_model(model)
                            enc = Tiktoken.encoding_for_model("gpt-4") #jal todo: fixed value since version 0.0.8 and 0.0.9 failed to install on SmartBot VM. Revert when fixed.
                            # all files in the docs_folder should be in text format
                            # first all files on 'include' folder then all files on 'filter' folder
                            ["#{path_to_session_folder}/docs_folder/include/**/*", "#{path_to_session_folder}/docs_folder/filter/**/*"].each do |folder|
                              Dir.glob(folder).each do |file|
                                next if File.directory?(file)
                                file_content = File.read(file)
                                num_tokens = enc.encode(file_content.to_s).length
                                docs_folder_prompts << {
                                  role: "user",
                                  content: [
                                    { type: "text", text: file_content, include_file: file.include?("/docs_folder/include/"), num_tokens: num_tokens, clean_text: file },
                                  ],
                                }
                              end
                            end
                            File.open("#{path_to_session_folder}/chatgpt_prompts.json", "w") do |f|
                              f.write(docs_folder_prompts.to_json)
                            end
                          end
                          if File.exist?("#{path_to_session_folder}/chatgpt_prompts.json")
                            # Extract all sentences from the prompts not including the system prompts or the user prompts that are images or responses from chatGPT
                            all_sentences = ""
                            prompts.each do |prompt|
                              if prompt[:role] == "user" and prompt[:content].size == 1 and prompt[:content][0][:type] == "text"
                                all_sentences += prompt[:content][0][:text] + " "
                              end
                            end
                            list_avoid = ["use", "set", "bash", term_to_avoid]
                            keywords = get_keywords(all_sentences, list_avoid: list_avoid)

                            # Read the JSON file
                            file_content = File.read("#{path_to_session_folder}/chatgpt_prompts.json")
                            json_data = JSON.parse(file_content, symbolize_names: true)

                            #remove keyword if keyword is in more than 50% of the documents
                            keywords_num_docs = {}
                            keywords.delete_if do |k|
                              num_found = 0
                              #check if the keyword is in the text field but not in the clean_text field (file name)
                              json_data.each do |entry|
                                num_found += 1 if entry[:content][0][:text].match?(/#{k}/i) and !entry[:content][0][:clean_text].to_s.match?(/#{k}/i)
                              end
                              keywords_num_docs[k] = num_found
                              num_found > (json_data.size / 2)
                            end

                            # Filter the JSON data to include only entries with keywords in the text field.
                            # Order the entries by the number of keywords found in the text field.
                            data_num_keywords = {}
                            json_data.each do |entry|
                              num_found = 0
                              total_occurrences = 0
                              keywords.each do |k|
                                num_found += 1 if entry[:content][0][:text].match?(/#{k}/i)
                                total_occurrences += entry[:content][0][:text].scan(/#{k}/i).size
                              end
                              entry[:content][0][:total_occurrences] = total_occurrences
                              data_num_keywords[num_found] ||= []
                              data_num_keywords[num_found] << entry
                            end
                            #delete all entries that have no keywords
                            data_num_keywords.delete(0)
                            #sort the data_num_keywords by the number of keywords found in the text field. From the highest to the lowest
                            data_num_keywords = data_num_keywords.sort_by { |k, v| k }.reverse.to_h
                            #sort by the total_occurrences descending
                            data_num_keywords.each do |k, v|
                              v.sort_by! { |entry| entry[:content][0][:total_occurrences] }.reverse!
                            end
                            #remove occurences of 1 keyword if 10 or more documents have been found with more than 1 keyword
                            if data_num_keywords.values.flatten.uniq.size > (json_data.size / 2) and data_num_keywords.keys.size > 1 and
                               data_num_keywords.key?(1) and (data_num_keywords.values.flatten.uniq.size - data_num_keywords[1].size) >= 10

                              #remove data_num_keywords for entries that have less than 2 keywords found
                              data_num_keywords.delete(1)
                            end

                            #flatten the data_num_keywords
                            filtered_data = data_num_keywords.values.flatten.uniq

                            #add all the entries that have the include_file set to true
                            json_data.each do |entry|
                              if entry[:content][0][:include_file]
                                filtered_data << entry
                              end
                            end

                            # put on top of the filtered_data the entries that have the include_file set to true
                            filtered_data.sort_by! { |entry| entry[:content][0][:include_file] ? 0 : 1 }

                            #remove key "include_file" and total_occurrences from filtered_data
                            filtered_data.each do |entry|
                              entry[:content].each do |content_block|
                                content_block.delete(:include_file)
                                content_block.delete(:total_occurrences)
                              end
                            end
                            filtered_data.uniq!

                            #enc = Tiktoken.encoding_for_model(model)
                            enc = Tiktoken.encoding_for_model("gpt-4") #jal todo: fixed value since version 0.0.8 and 0.0.9 failed to install on SmartBot VM. Revert when fixed.
                            prompts_orig = prompts.deep_copy
                            prompts = filtered_data + prompts
                            #content = (prompts || []).map do |entry|
                            #  (entry[:content] || []).map { |content_block| content_block[:text] }
                            #end.flatten
                            content = ""
                            prompts.each do |prompt|
                              content += prompt[:content][0][:text] if prompt.key?(:content) and prompt[:content][0].key?(:text)
                            end

                            num_tokens = enc.encode(content.to_s).length

                            respond ":information_source: The number of tokens in the prompt including all filtered docs is *#{num_tokens}*.\n\tWe will remove docs to ensure we don't reach the max num of allowed tokens for this ChatGPT model." if num_tokens > max_num_tokens
                            if num_tokens > (max_num_tokens - 1000) #since the number of tokens is not exact, we allow 1000 tokens less
                              #remove filtered_data one by one from the end until the number of tokens is less than max_num_tokens
                              while num_tokens > (max_num_tokens - 1000) and filtered_data.size > 0
                                filtered_data.pop
                                prompts = filtered_data + prompts_orig
                                content = ""
                                num_tokens = 0
                                prompts.each do |prompt|
                                  if prompt[:content][0].key?(:num_tokens) and prompt[:content][0][:num_tokens] > 0
                                    num_tokens += prompt[:content][0][:num_tokens]
                                  else
                                    if prompt.key?(:content) and prompt[:content][0].key?(:text)
                                      content += prompt[:content][0][:text]
                                    end
                                  end
                                end
                                num_tokens += enc.encode(content.to_s).length if content != ""
                              end
                            end
                            num_folder_docs = filtered_data.size
                          end
                          #delete num_tokens from content
                          prompts.each do |entry|
                            entry[:content].each do |content_block|
                              content_block.delete(:num_tokens)
                            end
                          end
                        end
                        if @chat_gpt_default_model != model and File.exist?("#{config.path}/openai/restricted_models.yaml")
                          restricted_models = YAML.load_file("#{config.path}/openai/restricted_models.yaml")
                          if restricted_models.key?(model) and !restricted_models[model].include?(team_id_user_creator) and !restricted_models[model].include?(user_creator)
                            respond "You don't have access to this model: #{model}. You can request access to an admin user."
                            restricted = true
                          end
                        end
                        if !restricted
                          success, res = SlackSmartBot::AI::OpenAI.send_gpt_chat(@ai_open_ai[team_id_user_creator][:chat_gpt][:client], model, prompts, @ai_open_ai[team_id_user_creator].chat_gpt)
                          if success
                            @ai_gpt[team_id_user_creator][session_name] << { role: "assistant", content: [{ type: "text", text: res }] }
                            @ai_gpt[team_id_user_creator][session_name] << system_prompt if system_prompt
                          end
                        end
                      end
                      unless restricted
                        #enc = Tiktoken.encoding_for_model(model)
                        enc = Tiktoken.encoding_for_model("gpt-4") #jal todo: fixed value since version 0.0.8 and 0.0.9 failed to install on SmartBot VM. Revert when fixed.
                        content = ""
                        prompts.each do |prompt|
                          content += prompt[:content][0][:text] if prompt.key?(:content) and prompt[:content][0].key?(:text)
                        end

                        num_tokens = enc.encode(content.to_s).length

                        if num_tokens > max_num_tokens and type != :clean
                          message_max_tokens = ":warning: The total number of tokens in the prompt is #{num_tokens}, which is greater than the maximum number of tokens allowed for the model (#{max_num_tokens})."
                          message_max_tokens += "\nTry to be more concrete writing your prompt. The number of docs attached according to your prompt was #{num_folder_docs}\n" if num_folder_docs > 0
                          respond message_max_tokens
                        end

                        if session_name == ""
                          temp_session_name = @ai_gpt[team_id_user_creator][""].first.content.first.text.to_s[0..35] #jal
                          res_slack_mkd = transform_to_slack_markdown(res.to_s.strip)
                          if num_folder_docs > 0
                            docs_message = "\n:notebook_with_decorative_cover: *#{num_folder_docs} documents* were added for this prompt (keywords: _#{keywords.sort[0..9].join(", ")}#{" ..." if keywords.size > 10}_)\n\n"
                          else
                            docs_message = ""
                          end
                          obj_id = @ai_gpt[team_id_user_creator][""].first.object_id
                          respond "*ChatGPT* Temporary session: _<#{temp_session_name.gsub("\n", " ").gsub("`", " ")}...>_ (#{obj_id}) model: #{model} num_tokens: #{num_tokens}#{docs_message}\n#{res_slack_mkd}", split: false
                          if res.to_s.strip == ""
                            respond "It seems like GPT is not responding. Please try again later or use another model, as it might be overloaded."
                          end
                          #to avoid logging the prompt or the response
                          if config.encrypt
                            Thread.current[:encrypted] ||= []
                            Thread.current[:encrypted] << message
                          end
                        elsif res.to_s.strip == ""
                          res = "\nAll prompts were removed from session." if delete_history
                          respond "*ChatGPT* Session _<#{session_name}>_ model: #{model}#{res}"
                          respond "It seems like GPT is not responding. Please try again later or use another model, as it might be overloaded." if message != ""
                        else
                          res_slack_mkd = transform_to_slack_markdown(res.to_s.strip)
                          if num_folder_docs > 0
                            docs_message = "\n:open_file_folder: #{num_folder_docs} documents from the folder were added to the prompts."
                          else
                            docs_message = ""
                          end
                          respond "*ChatGPT* Session _<#{session_name}>_ model: #{model} num_tokens: #{num_tokens}#{docs_message}\n#{res_slack_mkd}", split: false
                        end
                        if urls_messages.size > 0
                          respond urls_messages.join("\n")
                        end
                      end
                    end
                    update_openai_sessions(session_name, team_id: team_creator, user_name: user_creator) unless session_name == "" or !success or restricted
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
