class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat_use_model(model, dont_save_stats: false)
            save_stats(__method__) unless dont_save_stats
            open_ai_models('', just_models: true) if @open_ai_models.empty?
            model_selected = @open_ai_models.select{|m| m.include?(model)}
            if model_selected.size == 1
              model = model_selected[0]
              user = Thread.current[:user].dup
              if @chat_gpt_collaborating.key?(user.name) and @chat_gpt_collaborating[user.name].key?(Thread.current[:thread_ts])
                user_creator = @chat_gpt_collaborating[user.name][Thread.current[:thread_ts]][:user_creator]
                session_name = @chat_gpt_collaborating[user.name][Thread.current[:thread_ts]][:session_name]
              else
                user_creator = user.name
                @active_chat_gpt_sessions[user_creator] ||= {}
                if @active_chat_gpt_sessions[user_creator].key?(Thread.current[:thread_ts])
                  session_name = @active_chat_gpt_sessions[user_creator][Thread.current[:thread_ts]]
                elsif @active_chat_gpt_sessions[user_creator].key?(Thread.current[:dest])
                  session_name = @active_chat_gpt_sessions[user_creator][Thread.current[:dest]]
                else
                  session_name = ''
                end  
              end 
              if @open_ai.key?(user_creator) and @open_ai[user_creator].key?(:chat_gpt) and @open_ai[user_creator][:chat_gpt].key?(:sessions) and 
                @open_ai[user_creator][:chat_gpt][:sessions].key?(session_name)
                @open_ai[user_creator][:chat_gpt][:sessions][session_name][:model] = model
                respond "Model for this session is now #{model}" unless dont_save_stats
                update_openai_sessions(session_name, user_name: user_creator) unless session_name == ''
              end
            elsif model_selected.size > 1
              respond "There are more than one model with that name. Please be more specific: #{model_selected.join(', ')}"
            else
              respond "There is no model with that name."
            end
          end
        end
      end
    end
  end
end
