class SlackSmartBot
  module Commands
    module General
      module Teams
        def see_vacations_team(user, team_name, date, add_stats: true, filter_members: [])
          save_stats(__method__) if add_stats

          get_teams()
          teams = @teams.deep_copy
          if teams.empty?
            respond "There are no teams added yet. Use `add team` command to add a team."
          elsif team_name.to_s != "" and !teams.key?(team_name.to_sym) and (teams.keys.select { |t| (t.to_s.gsub("-", "").gsub("_", "") == team_name.to_s) }).empty?
            respond "It seems like the team *#{team_name}* doesn't exist.\nRelated commands `add team TEAM_NAME PROPERTIES`, `see team TEAM_NAME`, `see teams`"
          else
            teams.each do |name, team|
              if team_name == name.to_s or (name.to_s.gsub("-", "").gsub("_", "") == team_name.to_s)
                team_name = name.to_s
                break
              end
            end
            date.gsub!("-", "/")
            get_vacations()
            members_by_country_region = {}
            team = teams[team_name.to_sym]
            assigned_members = team.members.values.flatten
            assigned_members.uniq!
            assigned_members.dup.each do |m|
              user_info = find_user(m)
              assigned_members.delete(m) if user_info.nil? or user_info.deleted
            end

            channels_members = [] #todo: check if this is used in here. Remove.
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
                    user_info = find_user(m)
                    team_members << "#{user_info.team_id}_#{user_info.name}" unless user_info.nil? or user_info.is_app_user or user_info.is_bot
                  end
                end
              end
              team_members.flatten!
              all_team_members += team_members
              all_team_members.uniq!
            end
            if filter_members.size > 0
              all_team_members = all_team_members & filter_members
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
              if config[:public_holidays].key?(:default_calendar)
                defaulted_country_region = config[:public_holidays][:default_calendar].downcase
              else
                defaulted_country_region = ""
              end
              all_team_members.each do |m|
                info = find_user(m)
                unless info.nil?
                  country_region = ""
                  if @vacations.key?(m) and @vacations[m][:public_holidays].to_s != ""
                    country_region = @vacations[m][:public_holidays].downcase
                  elsif config[:public_holidays].key?(:default_calendar) and country_region.empty?
                    country_region = defaulted_country_region
                  end
                  members_by_country_region[country_region] ||= []
                  members_by_country_region[country_region] << "#{info.team_id}_#{info.name}"
                  if @vacations.key?(m)
                    v = ""
                    (from..(from + 20)).each do |d|
                      v += "#{d.strftime("%d")} " if d.wday == 1 or d == from
                      on_vacation = false
                      @vacations[m].periods ||= []
                      @vacations[m].periods.each do |p|
                        if p.from <= d.strftime("%Y/%m/%d") and p.to >= d.strftime("%Y/%m/%d")
                          if d.wday == 0 or d.wday == 6
                            v += ":large_orange_square: "
                          else
                            v += ":large_red_square: "
                          end
                          on_vacation = true
                          break
                        end
                      end
                      unless on_vacation
                        if country_region != "" and (!@public_holidays.key?(country_region) or !@public_holidays[country_region].key?(d.year.to_s))
                          country, location = country_region.split("/")
                          public_holidays(country.to_s, location.to_s, d.year.to_s, "", "", add_stats: false, publish_results: false)
                        end
                        if @public_holidays.key?(country_region) and @public_holidays[country_region].key?(d.year.to_s)
                          phd = @public_holidays[country_region][d.year.to_s].date.iso
                        else
                          phd = []
                        end
                        date_text = d.strftime("%Y-%m-%d")
                        if phd.include?(date_text)
                          v += ":large_red_square: "
                        elsif d.wday == 0 or d.wday == 6
                          v += ":large_yellow_square: "
                        else
                          v += ":white_square: "
                        end
                      end
                    end
                  else
                    v = ""
                    (from..(from + 20)).each do |d|
                      if country_region != "" and (!@public_holidays.key?(country_region) or !@public_holidays[country_region].key?(d.year.to_s))
                        country, location = country_region.split("/")
                        public_holidays(country.to_s, location.to_s, d.year.to_s, "", "", add_stats: false, publish_results: false)
                      end
                      if @public_holidays.key?(country_region) and @public_holidays[country_region].key?(d.year.to_s)
                        phd = @public_holidays[country_region][d.year.to_s].date.iso
                      else
                        phd = []
                      end
                      if d.wday == 1 or d == from
                        v += "#{d.strftime("%d")} "
                      end
                      date_text = d.strftime("%Y-%m-%d")
                      if phd.include?(date_text)
                        v += ":large_red_square: "
                      elsif d.wday == 0 or d.wday == 6
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
                        image_url: info.profile.image_24,
                        alt_text: info.name,
                      },
                      {
                            type: "plain_text",
                            text: v,
                          },
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
              message = ""
              if !defaulted_country_region.empty?
                message = "Defaulted public holidays calendar: #{defaulted_country_region}\n"
              end
              if members_by_country_region.size > 0 and members_by_country_region.keys.size > 1
                message_tmp = []
                members_by_country_region.each do |region, members|
                  #use only the user name on members
                  members_names = members.map { |m| m.split("_")[1..-1].join("_") }
                  message_tmp << "`#{region}`: <#{members_names.sort.join(", ")}>"
                end
                message += "Members by region:\n\t#{message_tmp.join(". ")}\n"
              end
              if all_team_members.include?(user.name)
                message += "To change your public holidays calendar, use the command `set public holidays to COUNTRY/STATE`. "
                message += "\nExamples: `set public holidays to Iceland`, `set public holidays to Spain/Madrid`"
              end
              respond message
            end
          end
        end
      end
    end
  end
end
