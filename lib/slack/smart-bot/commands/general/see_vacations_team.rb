class SlackSmartBot
  def see_vacations_team(user, team_name, date, add_stats: true)
    save_stats(__method__) if add_stats

    get_teams()
    teams = @teams.deep_copy
    if teams.empty?
      respond "There are no teams added yet. Use `add team` command to add a team."
    elsif team_name.to_s != "" and !teams.key?(team_name.to_sym) and (teams.keys.select { |t| (t.to_s.gsub("-", "").gsub("_", "") == team_name.to_s) }).empty?
      respond "It seems like the team *#{team_name}* doesn't exist.\nRelated commands `add team TEAM_NAME PROPERTIES`, `see team TEAM_NAME`, `see teams`"
    else
      teams.each do |name, team|
        if team_name==name.to_s or (name.to_s.gsub("-", "").gsub("_", "") == team_name.to_s)
          team_name = name.to_s
          break
        end
      end
      date.gsub!('-','/')
      get_vacations()
      team = teams[team_name.to_sym]
      assigned_members = team.members.values.flatten
      assigned_members.uniq!
      assigned_members.dup.each do |m|
        user_info = @users.select { |u| u.id == m or (u.key?(:enterprise_user) and u.enterprise_user.id == m) or u.name == m or (u.key?(:enterprise_user) and u.enterprise_user.name == m) }[-1]
        assigned_members.delete(m) if user_info.nil? or user_info.deleted
      end

      channels_members = []
      all_team_members = assigned_members.dup
      if team.channels.key?("members")
        team_members = []
        team.channels["members"].each do |ch|
          get_channels_name_and_id() unless @channels_id.key?(ch)
          tm = get_channel_members(@channels_id[ch])
          if tm.nil?
            respond ":exclamation: Add the Smart Bot to *##{ch}* channel to be able to get the list of members.", dest
          else
            channels_members << @channels_id[ch]
            tm.each do |m|
              user_info = @users.select { |u| u.id == m or (u.key?(:enterprise_user) and u.enterprise_user.id == m) }[-1]
              team_members << user_info.name unless user_info.is_app_user or user_info.is_bot
            end
          end
        end
        team_members.flatten!
        all_team_members += team_members
        all_team_members.uniq!
      end
      unless all_team_members.empty?
        blocks_header = 
          {
                    "type": "context",
                    elements: [
                      {
                          type: "mrkdwn",
                          text: "*Time Off #{team_name} team* from #{date} ",
                        },
                    ],
                  }
        
        from = Date.parse(date, "%Y/%m/%d")
        blocks = []
        all_team_members.each do |m|
          @users = get_users() if @users.empty?
          info = @users.select { |u| u.id == m or (u.key?(:enterprise_user) and u.enterprise_user.id == m) or u.name == m or (u.key?(:enterprise_user) and u.enterprise_user.name == m) }[-1]
          unless info.nil?
            info = get_user_info(info.id)
            if @vacations.key?(m)
              v = ""
              (from..(from+20)).each do |d|
                v+="#{d.strftime("%d")} " if d.wday==1 or d==from
                on_vacation = false
                @vacations[m].periods.each do |p|
                  if p.from <= d.strftime("%Y/%m/%d") and p.to >= d.strftime("%Y/%m/%d")
                    if d.wday == 0 or d.wday == 6
                      v+=":large_orange_square: "
                    else
                      v+=":large_red_square: "
                    end
                    on_vacation=true
                    break
                  end 
                end
                unless on_vacation
                  if d.wday == 0 or d.wday == 6
                    v += ":large_yellow_square: "
                  else
                    v+= ":white_square: " 
                  end
                end
              end
            else
              v = ""
              (from..(from+20)).each do |d|
                if d.wday==1 or d==from
                  v += "#{d.strftime("%d")} " 
                end
                if d.wday == 0 or d.wday == 6
                  v += ":large_yellow_square: "
                else
                  v += ":white_square: "
                end
              end
            end

            blocks << {
              type: "context",
              elements: [
                {
                            type: "image",
                            image_url: info.user.profile.image_24,
                            alt_text: info.user.name,
                          },
                          {
                            type: "plain_text",
                            text: v
                          }  
              ],
            }
          end
        end
        first = true
        blocks.each_slice(10).each do |b|
          if first 
            b.unshift(blocks_header)
            first = false
          end
          respond blocks: b
        end

      end


    end
  end
end
