class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat_delete_session(session_name)
            save_stats(__method__)

            user = Thread.current[:user].dup
            team_id_user = Thread.current[:team_id_user]

            @active_chat_gpt_sessions[team_id_user] ||= {}

            #todo: add confirmation message
            @open_ai[team_id_user] ||= {}
            @open_ai[team_id_user][:chat_gpt] ||= {}
            @open_ai[team_id_user][:chat_gpt][:sessions] ||= {}
            if @open_ai[team_id_user][:chat_gpt][:sessions].key?(session_name)
              delete_threads = []
              @active_chat_gpt_sessions[team_id_user].each do |thread_ts, sname|
                delete_threads << thread_ts if sname == session_name
              end
              delete_threads.each do |thread_ts|
                @active_chat_gpt_sessions[team_id_user].delete(thread_ts)
                @listening[team_id_user].delete(thread_ts) if @listening.key?(team_id_user)
                @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:collaborators].each do |collaborator|
                  collaborator_name = collaborator.split("_")[1..-1].join("_")
                  @listening[collaborator_name].delete(thread_ts) if @listening.key?(collaborator_name)
                  @chat_gpt_collaborating[collaborator].delete(thread_ts) if @chat_gpt_collaborating.key?(collaborator)
                end
              end

              @open_ai[team_id_user][:chat_gpt][:sessions].delete(session_name)

              update_openai_sessions(session_name)
              respond "*ChatGPT*: Session *#{session_name}* deleted."
            else
              respond "*ChatGPT*: You don't have a session with that name.\nCall `chatGPT list sessions` to see your saved sessions."
            end
          end
        end
      end
    end
  end
end
