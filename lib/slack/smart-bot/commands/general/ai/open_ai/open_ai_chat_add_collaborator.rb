class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat_add_collaborator(cname)
            save_stats(__method__)

            user = Thread.current[:user].dup
            @active_chat_gpt_sessions[user.name] ||= {}

            if @active_chat_gpt_sessions[user.name].key?(Thread.current[:thread_ts])
              session_name = @active_chat_gpt_sessions[user.name][Thread.current[:thread_ts]]
            elsif @active_chat_gpt_sessions[user.name].key?(Thread.current[:dest])
              session_name = @active_chat_gpt_sessions[user.name][Thread.current[:dest]]
            else
              session_name = ''
            end

            if session_name != "" and @active_chat_gpt_sessions[user.name].key?(Thread.current[:thread_ts])
              collaborator = @users.select { |u| u.id == cname or (u.key?(:enterprise_user) and u.enterprise_user.id == cname) }[-1]
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
          end
        end
      end
    end
  end
end
