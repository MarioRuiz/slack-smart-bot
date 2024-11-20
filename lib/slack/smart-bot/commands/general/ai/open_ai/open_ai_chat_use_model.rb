class SlackSmartBot
  module Commands
    module General
      module AI
        module OpenAI
          def open_ai_chat_use_model(model, dont_save_stats: false)
            save_stats(__method__) unless dont_save_stats
            open_ai_models("", just_models: true) if @open_ai_models.empty?
            model_selected = @open_ai_models.select { |m| m == model }
            model_selected = @open_ai_models.select { |m| m.include?(model) } if model_selected.empty?
            if model_selected.size == 1
              model = model_selected[0]
              user = Thread.current[:user].dup
              team_id_user = Thread.current[:team_id_user]

              user_name = user.name

              restricted = false
              if File.exist?("#{config.path}/openai/restricted_models.yaml")
                restricted_models = YAML.load_file("#{config.path}/openai/restricted_models.yaml")
                if restricted_models.key?(model) and !restricted_models[model].include?(team_id_user) and !restricted_models[model].include?(user_name)
                  respond "You don't have access to this model. You can request access to an admin user."
                  restricted = true
                end
              end
              unless restricted
                if @chat_gpt_collaborating.key?(team_id_user) and @chat_gpt_collaborating[team_id_user].key?(Thread.current[:thread_ts])
                  user_creator = @chat_gpt_collaborating[team_id_user][Thread.current[:thread_ts]][:user_creator]
                  team_creator = @chat_gpt_collaborating[team_id_user][Thread.current[:thread_ts]][:team_creator]
                  team_id_user_creator = team_creator + "_" + user_creator
                  session_name = @chat_gpt_collaborating[team_id_user][Thread.current[:thread_ts]][:session_name]
                else
                  user_creator = user.name
                  team_creator = user.team_id
                  team_id_user_creator = team_creator + "_" + user_creator

                  @active_chat_gpt_sessions[team_id_user_creator] ||= {}
                  if @active_chat_gpt_sessions[team_id_user_creator].key?(Thread.current[:thread_ts])
                    session_name = @active_chat_gpt_sessions[team_id_user_creator][Thread.current[:thread_ts]]
                  elsif @active_chat_gpt_sessions[team_id_user_creator].key?(Thread.current[:dest])
                    session_name = @active_chat_gpt_sessions[team_id_user_creator][Thread.current[:dest]]
                  else
                    session_name = ""
                  end
                end
                if @open_ai.key?(team_id_user_creator) and @open_ai[team_id_user_creator].key?(:chat_gpt) and @open_ai[team_id_user_creator][:chat_gpt].key?(:sessions) and
                   @open_ai[team_id_user_creator][:chat_gpt][:sessions].key?(session_name)
                  @open_ai[team_id_user_creator][:chat_gpt][:sessions][session_name][:model] = model
                  respond "Model for this session is now #{model}" unless dont_save_stats
                  update_openai_sessions(session_name, team_id: team_creator, user_name: user_creator) unless session_name == ""
                end
              end
            elsif model_selected.size > 1
              respond "There are more than one model with that name. Please be more specific: #{model_selected.join(", ")}"
            else
              respond "There is no model with that name."
            end
          end
        end
      end
    end
  end
end
