class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat_delete_session(session_name)
            save_stats(__method__)

            user = Thread.current[:user].dup
            @active_chat_gpt_sessions[user.name] ||= {}

            #todo: add confirmation message
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
                @listening[user.name].delete(thread_ts) if @listening.key?(user.name)
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
          end
        end
      end
    end
  end
end
