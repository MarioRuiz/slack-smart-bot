class SlackSmartBot
  module Commands
    module General
      module Teams
        def ping_team(user, type, team_name, member_type, message)
          if type == :ping
            save_stats(:ping_team)
            icon = ":large_green_circle:"
          else
            save_stats(:contact_team)
            icon = ":email:"
          end
          if Thread.current[:dest][0] == "D"
            respond "This command cannot be called from a DM"
          else
            get_teams()
            if !@teams.key?(team_name.to_sym)
              respond "It seems like the team *#{team_name}* doesn't exist.\nRelated commands `add team TEAM_NAME PROPERTIES`, `see team TEAM_NAME`, `see teams`"
            else
              team = @teams[team_name.to_sym].deep_copy

              assigned_members = team.members.values.flatten
              assigned_members.uniq!
              assigned_members.dup.each do |m|
                # extract the team_id from the member name: team_id_user_name. so everything after the first _ is the user_name. user_name can include _.
                user_info = find_user(m)
                assigned_members.delete(m) if user_info.nil? or user_info.deleted
              end
              unassigned_members = []
              not_on_team_channel = []

              if ((!team.members.key?(member_type) or member_type == "all") and team.channels.key?("members"))
                team_members = []
                team.channels["members"].each do |ch|
                  get_channels_name_and_id() unless @channels_id.key?(ch)
                  tm = get_channel_members(@channels_id[ch])
                  tm.each do |m|
                    user_info = find_user(m)
                    team_members << "#{user_info.team_id}_#{user_info.name}" unless user_info.nil? or user_info.is_app_user or user_info.is_bot or user_info.deleted
                  end
                end
                team_members.flatten!
                team_members.uniq!
                unassigned_members = team_members - assigned_members
                unassigned_members.delete("#{config.team_id}_#{config.nick}")

                unless unassigned_members.empty?
                  um = unassigned_members.dup
                  um.each do |m|
                    user_info = find_user(m)
                    unless user_info.nil? or user_info.profile.title.to_s == "" or user_info.deleted
                      team.members[user_info.profile.title.to_snake_case] ||= []
                      team.members[user_info.profile.title.to_snake_case] << m
                      unassigned_members.delete(m)
                    end
                  end
                  unless unassigned_members.empty?
                    team.members["unassigned"] ||= []
                    team.members["unassigned"] += unassigned_members
                    team.members["unassigned"].sort!
                  end
                end
              end

              if team.members.key?(member_type) or member_type == "all"
                if member_type == "all"
                  members_list = team.members.values.flatten.uniq.shuffle
                else
                  members_list = team.members[member_type].shuffle
                end
                if type == :ping
                  active_members = []
                  members_list.each do |member|
                    member_info = find_user(member)
                    unless member_info.nil? or member_info.deleted
                      active = (get_presence(member_info.id).presence.to_s == "active")
                      active_members << member if active
                    end
                  end
                  members = active_members
                else
                  members = members_list
                end
                members.dup.each do |m|
                  user_info = find_user(m)
                  members.delete(m) if user_info.nil? or user_info.deleted
                end

                if members.size > 0
                  members_names = members.map { |m| m.split("_")[1..-1].join("_") }
                  respond "#{icon} *#{type} #{team_name} team #{member_type}*\nfrom <@#{user.name}>\nto <@#{members_names[0..29].join(">, <@")}>#{", #{members_names[30..-1].join(", ")}" if members.size > 30} \n> #{message.split("\n").join("\n> ")}"
                elsif type == :ping
                  respond "It seems like there are no available #{member_type} members on #{team_name} team. Please call `see team #{team_name}`"
                else
                  respond "It seems like there are no #{member_type} members on #{team_name} team. Please call `see team #{team_name}`"
                end
              else
                respond "The member type #{member_type} doesn't exist, please call `see team #{team_name}`"
              end
            end
          end
        end
      end
    end
  end
end
