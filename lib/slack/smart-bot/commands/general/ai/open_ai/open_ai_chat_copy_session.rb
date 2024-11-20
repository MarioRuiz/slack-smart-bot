class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat_copy_session(team_orig, user_orig, session_name, new_session_name, temporary_session: false)
            if user_orig == ""
              save_stats(__method__)
            else
              save_stats(:open_ai_chat_copy_session_from_user)
            end

            user = Thread.current[:user].dup
            team_id = user.team_id
            if user_orig == ""
              user_orig = user.name
              team_orig = team_id
            end
            team_orig = team_id if team_orig == ""

            dest = Thread.current[:dest]
            get_openai_sessions()
            orig_team_id_user = team_orig + "_" + user_orig
            team_id_user = team_id + "_" + user.name

            if temporary_session
              if @open_ai.key?(team_id_user) and @open_ai[team_id_user][:chat_gpt][:sessions].key?("") and
                 @open_ai[team_id_user][:chat_gpt][:sessions][""].key?(:thread_ts)
                @open_ai[team_id_user][:chat_gpt][:sessions][""][:thread_ts].each do |thread_ts|
                  if thread_ts != Thread.current[:thread_ts] && @listening[:threads].key?(thread_ts)
                    unreact :running, thread_ts, channel: @listening[:threads][thread_ts]
                    message_chatgpt = ":information_source: I'm sorry, but I'm no longer listening to this thread since you started a new temporary session."
                    respond message_chatgpt, @listening[:threads][thread_ts], thread_ts: thread_ts
                    @listening[team_id_user].delete(thread_ts)
                    @listening[:threads].delete(thread_ts)
                    @open_ai[team_id_user][:chat_gpt][:sessions][""][:collaborators].each do |team_id_user_collaborator|
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
            end

            if user_orig != user.name and dest[0] == "D" and @open_ai.key?(orig_team_id_user) and
               @open_ai[orig_team_id_user][:chat_gpt][:sessions].key?(session_name) and
               @open_ai[orig_team_id_user][:chat_gpt][:sessions][session_name][:shared].size > 0
              members_shared = []
              @open_ai[orig_team_id_user][:chat_gpt][:sessions][session_name][:shared].each do |shared|
                members_shared += get_channel_members(shared)
              end
              members_shared.uniq!
            else
              members_shared = []
            end
            if !@open_ai.key?(orig_team_id_user)
              respond "*ChatGPT*: The user *#{user_orig}* doesn't exist."
              return false
            elsif !@open_ai[orig_team_id_user][:chat_gpt][:sessions].key?(session_name)
              respond "*ChatGPT*: The session *#{session_name}* doesn't exist."
              return false
            elsif user_orig != user.name and dest[0] == "D" and
                  !@open_ai[orig_team_id_user][:chat_gpt][:sessions][session_name][:public] and
                  @open_ai[orig_team_id_user][:chat_gpt][:sessions][session_name][:shared].size > 0 and
                  !members_shared.include?(user.id)
              respond "*ChatGPT*: The session *#{session_name}* doesn't exist or it is not shared."
            elsif user_orig != user.name and dest[0] != "D" and
                  !@open_ai[orig_team_id_user][:chat_gpt][:sessions][session_name][:public] and
                  !@open_ai[orig_team_id_user][:chat_gpt][:sessions][session_name][:shared].include?(dest)
              respond "*ChatGPT*: The session *#{session_name}* doesn't exist or it is not shared."
              return false
            else
              @open_ai[team_id_user] ||= {}
              @open_ai[team_id_user][:chat_gpt] ||= {}
              @open_ai[team_id_user][:chat_gpt][:sessions] ||= {}
              session_orig = @open_ai[orig_team_id_user][:chat_gpt][:sessions][session_name].deep_copy
              open_ai_new_session = {
                team_creator: team_id,
                user_creator: user.name,
                started: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
                last_activity: Time.now.strftime("%Y-%m-%d %H:%M:%S"),
                collaborators: [],
                num_prompts: session_orig[:num_prompts],
                model: session_orig[:model],
                shared: [],
                copy_of_session: session_name,
                copy_of_team: team_orig,
                copy_of_user: user_orig,
                users_copying: [],
                temp_copies: 0,
                own_temp_copies: 0,
                public: false,
                description: session_orig[:description],
                tag: session_orig[:tag],
                live_content: session_orig[:live_content],
                static_content: session_orig[:static_content],
                authorizations: session_orig[:authorizations],
              }
              if !temporary_session and (team_orig != team_id or user_orig != user.name)
                open_ai_new_session[:authorizations] = {}
                message_auth = "\n:lock: Authorizations were removed on copy."
              elsif !temporary_session and session_orig[:copy_of_session] != "" and
                    (session_orig[:copy_of_team] != team_id or session_orig[:copy_of_user] != user.name)
                open_ai_new_session[:authorizations] = {}
                message_auth = "\n:lock: Authorizations were removed on copy."
              else
                message_auth = ""
              end
              message_history = ""
              if team_orig != team_id or user_orig != user.name
                if session_orig.key?(:static_content)
                  session_orig[:static_content].each do |cont|
                    if cont.match?(/\AHistory of <#(\w+)>\Z/im) #jal66
                      respond "*ChatGPT*: The session *#{session_name}* contains the history of a Slack Channel. Sorry, but I can't copy it."
                      return false
                    end
                  end
                end
              end

              new_session_name = session_name if new_session_name == "" and !temporary_session
              session_names = @open_ai[team_id_user][:chat_gpt][:sessions].keys
              if session_names.include?(new_session_name) and !temporary_session
                number = session_names.join("\n").scan(/^#{new_session_name}(\d+)$/).max
                if number.nil?
                  number = "1"
                else
                  number = number.flatten[-1].to_i + 1
                end
                new_session_name = "#{new_session_name}#{number}"
              end

              @open_ai[team_id_user][:chat_gpt][:sessions][new_session_name] = open_ai_new_session
              @ai_gpt[team_id_user][""] = [] if temporary_session and @ai_gpt.key?(team_id_user)

              if user_orig != user.name or team_id != team_orig
                if temporary_session
                  @open_ai[orig_team_id_user][:chat_gpt][:sessions][session_name][:temp_copies] ||= 0
                  @open_ai[orig_team_id_user][:chat_gpt][:sessions][session_name][:temp_copies] += 1
                else
                  @open_ai[orig_team_id_user][:chat_gpt][:sessions][session_name][:users_copying] ||= []
                  @open_ai[orig_team_id_user][:chat_gpt][:sessions][session_name][:users_copying] << user.name
                end
                update_openai_sessions("", team_id: team_orig, user_name: user_orig)
              else
                if temporary_session
                  @open_ai[orig_team_id_user][:chat_gpt][:sessions][session_name][:own_temp_copies] ||= 0
                  @open_ai[orig_team_id_user][:chat_gpt][:sessions][session_name][:own_temp_copies] += 1
                  update_openai_sessions("", team_id: team_orig, user_name: user_orig)
                end
              end

              get_openai_sessions(session_name, team_id: team_orig, user_name: user_orig)
              @ai_gpt[team_id_user] ||= {}
              if @ai_gpt.key?(orig_team_id_user) and @ai_gpt[orig_team_id_user].key?(session_name)
                @ai_gpt[team_id_user][new_session_name] = @ai_gpt[orig_team_id_user][session_name].deep_copy
              else
                @ai_gpt[team_id_user][new_session_name] = []
              end
              update_openai_sessions(new_session_name, team_id: team_id, user_name: user.name) unless temporary_session

              if user_orig != user.name or team_id != team_orig
                if temporary_session
                  res_message = "*ChatGPT*: Session *#{session_name}* (#{user_orig}) copied to be used as a temporary session.#{message_auth}#{message_history}"
                else
                  res_message = "*ChatGPT*: Session *#{session_name}* (#{user_orig}) copied to #{new_session_name}.#{message_auth}#{message_history}\nNow you can call `^chatGPT #{new_session_name}` to use it."
                end
              else
                if temporary_session
                  res_message = "*ChatGPT*: Session *#{session_name}* copied to be used as a temporary session.#{message_auth}#{message_history}"
                else
                  res_message = "*ChatGPT*: Session *#{session_name}* copied to #{new_session_name}.#{message_auth}#{message_history}\nNow you can call `^chatGPT #{new_session_name}` to use it."
                end
              end
              if !@open_ai[team_id_user][:chat_gpt][:sessions][new_session_name][:live_content].nil? and
                 @open_ai[team_id_user][:chat_gpt][:sessions][new_session_name][:live_content].size > 0
                live_content = "\n:globe_with_meridians: *Live content*:\n\t\t - `#{@open_ai[team_id_user][:chat_gpt][:sessions][new_session_name][:live_content].join("`\n\t\t - `")}`"
                res_message += live_content
              end
              if !@open_ai[team_id_user][:chat_gpt][:sessions][new_session_name][:static_content].nil? and
                 @open_ai[team_id_user][:chat_gpt][:sessions][new_session_name][:static_content].size > 0
                static_content = "\n:pushpin: *Static content*:\n\t\t - `#{@open_ai[team_id_user][:chat_gpt][:sessions][new_session_name][:static_content].join("`\n\t\t - `")}`"
                res_message += static_content
              end

              if !@open_ai[team_id_user][:chat_gpt][:sessions][new_session_name][:authorizations].nil? and
                 @open_ai[team_id_user][:chat_gpt][:sessions][new_session_name][:authorizations].size > 0
                auth = "\n:lock: *Authorizations*:\n"
                @open_ai[team_id_user][:chat_gpt][:sessions][new_session_name][:authorizations].each do |host, header|
                  auth += "\t\t - `#{host}`: `#{header.keys.join("`, `")}`\n"
                end
                res_message += auth
              end
              respond res_message
              return true
            end
          end
        end
      end
    end
  end
end
