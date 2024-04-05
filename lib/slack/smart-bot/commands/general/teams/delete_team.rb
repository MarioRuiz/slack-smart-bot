class SlackSmartBot
  module Commands
    module General
      module Teams
        def delete_team(user, team_name)
          save_stats(__method__) if answer.empty?

          if Thread.current[:dest][0] == "D"
            respond "This command cannot be called from a DM"
          else
            get_teams()
            if @teams.key?(team_name.to_sym)
              assigned_members = @teams[team_name.to_sym].members.values.flatten
              assigned_members.uniq!
              all_team_members = assigned_members.dup
              team_members = []
              if @teams[team_name.to_sym].channels.key?("members")
                @teams[team_name.to_sym].channels["members"].each do |ch|
                  get_channels_name_and_id() unless @channels_id.key?(ch)
                  tm = get_channel_members(@channels_id[ch])
                  tm.each do |m|
                    user_info = find_user(m)
                    team_members << "#{user_info.team_id}_#{user_info.name}" unless user_info.nil? or user_info.is_app_user or user_info.is_bot
                  end
                end
              end
              team_members.flatten!
              team_members.uniq!
              all_team_members += team_members
              all_team_members.uniq!
            end
            if !@teams.key?(team_name.to_sym)
              respond "It seems like the team *#{team_name}* doesn't exist.\nRelated commands `add team TEAM_NAME PROPERTIES`, `see team TEAM_NAME`, `see teams`"
            elsif !(all_team_members + [@teams[team_name.to_sym].creator] + config.team_id_masters).flatten.include?("#{user.team_id}_#{user.name}")
              respond "You have to be a member of the team, the creator or a Master admin to be able to delete this team."
            else
              if answer.empty?
                ask "do you really want to delete the #{team_name} team? (yes/no)"
              else
                case answer
                when /yes/i, /yep/i, /sure/i
                  answer_delete
                  @teams.delete(team_name.to_sym)
                  require "fileutils"
                  time_deleted = Time.now.strftime("%Y%m%d%H%M%S")
                  FileUtils.mv(File.join(config.path, "teams", "t_#{team_name}.yaml"),
                               File.join(config.path, "teams", "t_#{team_name}_#{time_deleted}.yaml.deleted"))
                  deleted_memos_file = File.join(config.path, "teams", "t_#{team_name}_memos.yaml.deleted")
                  if File.exist?(deleted_memos_file)
                    FileUtils.mv(deleted_memos_file,
                                 File.join(config.path, "teams", "t_#{team_name}_memos_#{time_deleted}.yaml.deleted"))
                  end
                  update_teams()
                  respond "The team #{team_name} has been deleted."
                when /no/i, /nope/i, /cancel/i
                  answer_delete
                  respond "Ok, the team was not deleted"
                else
                  respond "I don't understand"
                  ask "do you really want to delete the #{team_name} team? (yes/no)"
                end
              end
            end
          end
        end
      end
    end
  end
end
