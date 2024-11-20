class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat_add_collaborator(cname)
            save_stats(__method__)

            user = Thread.current[:user]
            team_id = user.team_id
            team_id_user = Thread.current[:team_id_user]

            @active_chat_gpt_sessions[team_id_user] ||= {}

            if @active_chat_gpt_sessions[team_id_user].key?(Thread.current[:thread_ts])
              session_name = @active_chat_gpt_sessions[team_id_user][Thread.current[:thread_ts]]
            elsif @active_chat_gpt_sessions[team_id_user].key?(Thread.current[:dest])
              session_name = @active_chat_gpt_sessions[team_id_user][Thread.current[:dest]]
            else
              session_name = ""
            end

            if @active_chat_gpt_sessions[team_id_user].key?(Thread.current[:thread_ts])
              collaborator = find_user(cname)
              team_id_user_collaborator = collaborator.team_id + "_" + collaborator.name
              unless @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:collaborators].include?(team_id_user_collaborator)
                @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:collaborators] << team_id_user_collaborator
              end
              @listening[team_id_user_collaborator] ||= {}
              @listening[team_id_user_collaborator][Thread.current[:thread_ts]] = Time.now
              @chat_gpt_collaborating[team_id_user_collaborator] ||= {}
              @chat_gpt_collaborating[team_id_user_collaborator][Thread.current[:thread_ts]] ||= { team_creator: team_id, user_creator: user.name, session_name: session_name }
              respond "Now <@#{collaborator.name}> is a collaborator of this session only when on a thread.\nIn case you don't want to send a message as a prompt, just start the message with hyphen (-)."
            else
              respond "You can add collaborators for the chatGPT session only when started on a thread."
            end
          end
        end
      end
    end
  end
end
