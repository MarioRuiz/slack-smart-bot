class SlackSmartBot
  module Commands
    module General
      module Teams
        def add_team(user, name, options, info)
          save_stats(__method__)

          get_teams()
          if @teams.key?(name.to_sym)
            respond "It seems like the team *#{name}* already exists.\nRelated commands `update team TEAM_NAME PROPERTIES`, `delete team TEAM_NAME`, `see team TEAM_NAME`, `see teams`"
          else
            wrong = false
            team = { members: {}, channels: {} }
            last_type = nil
            type_detected = false
            options.split(/\s+/).each do |opt|
              type_detected = false
              if opt.match?(/^\s*$/)
                #blank
              elsif opt.match?(/^[\w\-]+$/i)
                last_type = opt
                type_detected = true
              elsif opt.match(/<@(\w+)>/i)
                team[:members][last_type] ||= []
                if last_type.nil?
                  wrong = true
                  respond "You need to specify the TYPE for the member."
                  break
                else
                  member_id = $1
                  member_info = @users.select { |u| u.id == member_id or (u.key?(:enterprise_user) and u.enterprise_user.id == member_id) }[-1]
                  if member_info.nil?
                    @users = get_users()
                    member_info = @users.select { |u| u.id == member_id or (u.key?(:enterprise_user) and u.enterprise_user.id == member_id) }[-1]
                  end
                  team[:members][last_type] << member_info.name
                end
              elsif opt.match(/<#(\w+)\|[^>]*>/i)
                team[:channels][last_type] ||= []
                if last_type.nil?
                  wrong = true
                  respond "You need to specify the TYPE for the channel."
                  break
                else
                  channel_id = $1
                  get_channels_name_and_id() unless @channels_name.keys.include?(channel_id)
                  channel = @channels_name[channel_id]
                  channel_members = get_channel_members(channel_id) unless channel.nil?
                  if channel.nil? or !channel_members.include?(config.nick_id)
                    respond ":exclamation: Add the Smart Bot to *<##{channel_id}>* channel first."
                    wrong = true
                    break
                  else
                    team[:channels][last_type] << channel
                  end
                end
              else
                respond "It seems like the members or channel list is not correct. Please double check."
                wrong = true
                break
              end
            end
            if type_detected #type added but not added a channel or user
              respond "It seems like the parameters supplied are not correct. Please double check."
              wrong = true
            end

            unless wrong
              get_teams()
              team[:info] = info
              team[:status] = :added
              team[:user] = user.name
              team[:creator] = user.name
              team[:date] = Time.now.strftime("%Y-%m-%dT%H:%M:%S.000Z")[0..18]
              new_team = {}
              team[:name] = name
              new_team[name.to_sym] = team
              update_teams(new_team)
              respond "The *#{name}* team has been added."
              see_teams(user, name, add_stats: false)
            end
          end
        end
      end
    end
  end
end
