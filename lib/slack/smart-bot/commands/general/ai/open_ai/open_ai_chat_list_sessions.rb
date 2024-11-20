class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat_list_sessions(type, tag: "") #type can be :own or :public or :shared
            save_stats(__method__)

            user = Thread.current[:user].dup
            team_id = user.team_id
            team_id_user = Thread.current[:team_id_user]

            channel = Thread.current[:dest]
            on_dm = channel[0] == "D"

            get_openai_sessions()
            check_users = []
            if type == :own
              check_users << team_id_user
            else
              check_users = @open_ai.keys
            end
            members = {}

            list_sessions = {}
            check_users.each do |team_user_name|
              if @open_ai.key?(team_user_name) and @open_ai[team_user_name].key?(:chat_gpt) and
                 @open_ai[team_user_name][:chat_gpt].key?(:sessions) and
                 @open_ai[team_user_name][:chat_gpt][:sessions].size > 0
                sessions = @open_ai[team_user_name][:chat_gpt][:sessions].keys.sort
                sessions.delete("")

                sessions.each do |session_name|
                  session = @open_ai[team_user_name][:chat_gpt][:sessions][session_name]
                  if type == :shared and on_dm and session.key?(:shared)
                    session[:shared].each do |channel_shared|
                      members[channel_shared] ||= get_channel_members(channel_shared)
                    end
                  end
                  if (type == :own and session[:user_creator] == user.name) or
                     (type == :public and session.key?(:public) and session[:public]) or
                     (type == :shared and session.key?(:shared) and session[:shared].include?(channel)) or
                     (type == :shared and session.key?(:shared) and on_dm and session[:shared].size > 0)
                    if tag == "" or (session.key?(:tag) and tag == session[:tag].to_s)
                      if type == :shared and on_dm
                        channels_check = []
                        session.shared.each do |channel_shared|
                          channels_check << channel_shared if members.key?(channel_shared) and !members[channel_shared].nil? and members[channel_shared].include?(user.id)
                        end
                      else
                        channels_check = [channel]
                      end
                      channels_check.each do |channel_check|
                        if !session.key?(:team_creator) or session[:team_creator] == ""
                          session[:team_creator] = config.team_id
                        end
                        #get the last context from prompts
                        team_user_creator = session[:team_creator] + "_" + session[:user_creator]
                        if !@ai_gpt.key?(team_user_creator) or !@ai_gpt[team_user_creator].key?(session_name)
                          get_openai_sessions(session_name, team_id: session[:team_creator], user_name: session[:user_creator])
                        end
                        if @ai_gpt.key?(team_user_creator) and @ai_gpt[team_user_creator].key?(session_name)
                          prompts_array = @ai_gpt[team_user_creator][session_name]
                        else
                          prompts_array = []
                        end
                        context = ""
                        if prompts_array.size > 0
                          prompts_array.reverse.each do |prompt|
                            if prompt[:role] == "system" and prompt[:content].size > 0 and prompt[:content][0][:type] == "text"
                              context = prompt[:content][0][:text]
                              break
                            end
                          end
                        end
                        list_session = []
                        list_session << "*`#{session_name}`*: "
                        list_session[-1] << "_#{session[:description]}_ " if session.key?(:description) and session[:description].to_s.strip != ""
                        list_session[-1] << "*(public)* " if session.key?(:public) and session[:public] and type != :public
                        list_session[-1] << "(shared on <##{session.shared.join(">, <#")}>) " if session.key?(:shared) and session[:shared].size > 0 and type != :shared
                        list_session[-1] << "\n\t:spiral_note_pad: *#{session.num_prompts}* prompts. "
                        list_session[-1] << " tag: >*#{session.tag}*. " if session.key?(:tag) and session[:tag].to_s != "" and tag == ""
                        list_session[-1] << "shared by: *#{session.user_creator}*. " if type != :own
                        list_session[-1] << "original creator: *#{session.copy_of_user}*. " if session.key?(:copy_of_user) and session[:copy_of_user] != "" and session[:copy_of_user] != session[:user_creator]
                        list_session[-1] << "model: #{session.model}. " if session.key?(:model) and session[:model] != ""
                        if on_dm and config.masters.include?(user.name)
                          list_session[-1] << "copies: #{session.users_copying.size}. " if session.key?(:users_copying) and session[:users_copying].size > 0
                          list_session[-1] << "users: #{session.users_copying.uniq.size}. " if session.key?(:users_copying) and session[:users_copying].size > 0
                          list_session[-1] << "temp copies: #{session.temp_copies}. " if session.key?(:temp_copies) and session[:temp_copies] > 0
                          list_session[-1] << "own temp copies: #{session.own_temp_copies}. " if session.key?(:own_temp_copies) and session[:own_temp_copies] > 0
                        else
                          num_copies = session.users_copying.size + session.temp_copies.to_i + session.own_temp_copies.to_i
                          list_session[-1] << "copies: #{num_copies}. " if num_copies > 0
                        end
                        list_session[-1] << "collaborators: *#{session.collaborators.join(", ").gsub("#{team_id}_", "")}*. " unless !session.key?(:collaborators) or session.collaborators.empty?
                        list_session[-1] << "last prompt: #{session.last_activity.gsub("-", "/")[0..15]}. " if type == :own
                        list_session[-1] << "\n\t:robot_face: context: #{context}" if context != ""
                        list_session[-1] << "\n\t:pushpin: static content:\n\t\t#{session.static_content.join("\n\t\t")}" if !session[:static_content].nil? and session[:static_content].size > 0
                        list_session[-1] << "\n\t:globe_with_meridians: live content:\n\t\t#{session.live_content.join("\n\t\t")}" if !session[:live_content].nil? and session[:live_content].size > 0
                        path_to_docs_folder_file = "#{config.path}/openai/#{session.team_creator}/#{session.user_creator}/#{session_name}/chatgpt_prompts.json"
                        if File.exist?(path_to_docs_folder_file)
                          num_docs = JSON.parse(File.read(path_to_docs_folder_file)).size
                          list_session[-1] << "\n\t:notebook_with_decorative_cover: #{num_docs} documents can be used in this session." if num_docs > 0
                        end
                        if session.key?(:authorizations) and session[:authorizations].size > 0
                          list_session[-1] << "\n\t:lock: authorizations:\n"
                          session[:authorizations].each do |key, value|
                            list_session[-1] << "\t\t#{key}\n"
                          end
                        end
                        list_sessions[channel_check] ||= []
                        list_sessions[channel_check] += list_session
                      end
                    end
                  end
                end
              end
            end
            if list_sessions.size > 0
              list_sessions.each do |channel, list|
                if type == :own
                  respond "*ChatGPT*: Your#{" >*#{tag}*" if tag != ""} sessions:\n\n#{list.join("\n\n")}", unfurl_links: false
                elsif type == :public
                  respond "*ChatGPT*: Public#{" >*#{tag}*" if tag != ""} sessions on #{config.team_name}:\n\n#{list.join("\n\n")}", unfurl_links: false
                elsif type == :shared
                  if channel[0] == "D" and @rules_imported[team_id_user].key?(user.name) and @rules_imported[team_id_user][user.name] != ""
                    respond "*ChatGPT*: Shared#{" >*#{tag}*" if tag != ""} sessions on <##{@rules_imported[team_id_user][user.name]}>:\n\n#{list.join("\n\n")}", unfurl_links: false
                  else
                    respond "*ChatGPT*: Shared#{" >*#{tag}*" if tag != ""} sessions on <##{channel}>:\n\n#{list.join("\n\n")}", unfurl_links: false
                  end
                end
              end
              respond "\n\n:information_source: To start using a session: `chatgpt use USER_SHARED SESSION_NAME` or `?? use SESSION_NAME PROMPT`" if type != :own
            else
              if type == :own
                respond "*ChatGPT*: You don't have any#{" >*#{tag}*" if tag != ""} sessions."
              else
                respond "*ChatGPT*: There are no#{" >*#{tag}*" if tag != ""} #{type} sessions."
              end
            end
          end
        end
      end
    end
  end
end
