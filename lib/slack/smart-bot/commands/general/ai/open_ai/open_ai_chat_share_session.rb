class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat_share_session(type, session_name, channel_id)
            save_stats(__method__)

            user = Thread.current[:user].dup

            @open_ai[user.name] ||= {}
            @open_ai[user.name][:chat_gpt] ||= {}
            @open_ai[user.name][:chat_gpt][:sessions] ||= {}
            if @open_ai[user.name][:chat_gpt][:sessions].key?(session_name)
              if type == :share
                if channel_id == ""
                  @open_ai[user.name][:chat_gpt][:sessions][session_name].public = true
                else
                  @open_ai[user.name][:chat_gpt][:sessions][session_name].shared << channel_id
                end
              elsif type == :stop
                if channel_id == ""
                  @open_ai[user.name][:chat_gpt][:sessions][session_name].public = false
                else
                  @open_ai[user.name][:chat_gpt][:sessions][session_name].shared.delete(channel_id)
                end
              end
              update_openai_sessions()
              if type == :share
                if channel_id == ""
                  respond "*GPT*: Session *#{session_name}* is now public."
                else
                  respond "*GPT*: Session *#{session_name}* is now shared on <##{channel_id}>."
                end
              elsif type == :stop
                if channel_id == ""
                  respond "*GPT*: Session *#{session_name}* is no longer public."
                else
                  respond "*GPT*: Session *#{session_name}* is no longer shared on <##{channel_id}>."
                end
              end
            else
              respond "*GPT*: You don't have a session with that name.\nCall `chatGPT list sessions` to see your saved sessions."
            end
          end
        end
      end
    end
  end
end
