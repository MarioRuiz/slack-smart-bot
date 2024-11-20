class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat_share_session(type, session_name, channel_id)
            save_stats(__method__)

            user = Thread.current[:user].dup
            team_id_user = Thread.current[:team_id_user]

            @open_ai[team_id_user] ||= {}
            @open_ai[team_id_user][:chat_gpt] ||= {}
            @open_ai[team_id_user][:chat_gpt][:sessions] ||= {}
            if @open_ai[team_id_user][:chat_gpt][:sessions].key?(session_name)
              if type == :share
                if channel_id == ""
                  @open_ai[team_id_user][:chat_gpt][:sessions][session_name].public = true
                else
                  @open_ai[team_id_user][:chat_gpt][:sessions][session_name].shared ||= []
                  @open_ai[team_id_user][:chat_gpt][:sessions][session_name].shared << channel_id
                end
              elsif type == :stop
                if channel_id == ""
                  if @open_ai[team_id_user][:chat_gpt][:sessions][session_name].public
                    @open_ai[team_id_user][:chat_gpt][:sessions][session_name].public = false
                  else
                    respond "*ChatGPT*: Session *#{session_name}* is not public."
                    return
                  end
                else
                  if @open_ai[team_id_user][:chat_gpt][:sessions][session_name].shared.include?(channel_id)
                    @open_ai[team_id_user][:chat_gpt][:sessions][session_name].shared.delete(channel_id)
                  else
                    respond "*ChatGPT*: Session *#{session_name}* is not shared on <##{channel_id}>."
                    return
                  end
                end
              end
              update_openai_sessions()
              if type == :share
                if channel_id == ""
                  respond "*ChatGPT*: Session *#{session_name}* is now public."
                else
                  respond "*ChatGPT*: Session *#{session_name}* is now shared on <##{channel_id}>."
                end
              elsif type == :stop
                if channel_id == ""
                  respond "*ChatGPT*: Session *#{session_name}* is no longer public."
                else
                  respond "*ChatGPT*: Session *#{session_name}* is no longer shared on <##{channel_id}>."
                end
              end
            else
              respond "*ChatGPT*: You don't have a session with that name.\nCall `chatGPT list sessions` to see your saved sessions."
            end
          end
        end
      end
    end
  end
end
