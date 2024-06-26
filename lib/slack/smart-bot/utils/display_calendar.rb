class SlackSmartBot
  def display_calendar(from_user_name, year, country_region: '')
    if @vacations.key?(from_user_name) and @vacations[from_user_name][:public_holidays].to_s != ""
      country_region = @vacations[from_user_name][:public_holidays].downcase
    elsif config[:public_holidays].key?(:default_calendar) and country_region.empty?
      country_region = config[:public_holidays][:default_calendar].downcase
    end
    country, location = country_region.split("/")
    local_day_time = local_time(country_region)
    if local_day_time.nil?
      today = Date.today
    else
      today = local_day_time.to_date
    end
    public_holidays(country.to_s, location.to_s, year, "", "", add_stats: false, publish_results: false)
    if from_user_name.empty?
      messages = ["*Calendar #{year} #{country_region}*"]
    else
      messages = ["*Time off #{year}*"]
    end
    days_of_vacations = 0
    (1..12).each do |m|
      date = Date.parse("#{year}/#{m}/1")
      month_name = date.strftime("%B")
      month_line = ""
      (1..6).each do |w|
        if date.month == m
          month_line += "#{date.strftime("%d")} "
        else
          month_line += ":white_small_square: "
        end

        if @public_holidays.key?(country_region) and @public_holidays[country_region].key?(year.to_s)
          phd = @public_holidays[country_region][year.to_s].date.iso
        else
          phd = []
        end
        (1..7).each do |d|
          wday = date.wday
          wday = 7 if wday == 0
          break if d >= 3 and w == 6 # week 6 cannot be more than wednesday
          date_text = date.strftime("%Y-%m-%d")
          if wday == d and date.month == m
            vacations_set = false
            public_holiday_set = false
            if phd.include?(date_text)
              if date == today
                month_line += ":large_red_circle: "
              else
                month_line += ":large_red_square: "
              end
              public_holiday_set = true
            end
            if !public_holiday_set
              if @vacations.key?(from_user_name) and @vacations[from_user_name].key?(:periods)
                @vacations[from_user_name][:periods].each do |period|
                  if date >= Date.parse(period[:from]) and date <= Date.parse(period[:to])
                    if period[:type] == "sick"
                      if date == today
                        month_line += ":thermometer: "
                      else
                        month_line += ":face_with_thermometer: "
                      end
                    elsif period[:type] == "sick child"
                      if date == today
                        month_line += ":baby_bottle: "
                      else
                        month_line += ":baby: "
                      end
                    elsif period[:type] == "vacation"
                      if date == today
                        month_line += ":evergreen_tree: "
                      else
                        month_line += ":palm_tree: "
                      end
                      if wday <= 5
                        days_of_vacations += 1
                      end
                    end
                    vacations_set = true
                    break
                  end
                end
              end
              if !vacations_set
                if wday == 6 || wday == 7
                  if date == today
                    month_line += ":large_yellow_circle: "
                  else
                    month_line += ":large_yellow_square: "
                  end
                else
                  if date == today
                    month_line += ":white_circle: "
                  else
                    month_line += ":white_square: "
                  end
                end
              end
            end
            date += 1
          else
            month_line += ":white_small_square: "
          end
        end
      end
      messages << "#{month_line}    #{month_name}\n"
    end
    if !from_user_name.empty?
      messages << "\n\n:large_yellow_square: weekend / :white_square: weekday / :white_small_square: not in month / :large_red_square: Public Holiday / :palm_tree: Vacation / :face_with_thermometer: Sick / :baby: Sick child"
      if country_region != ""
        if local_day_time.nil?
          local_str = "local time not found"
        else
          local_str = local_day_time.strftime("%Y-%m-%d %H:%M")
        end
        messages << "Your public holidays are set for #{country_region.downcase} (#{local_str}). Call `set public holidays to COUNTRY/REGION` if you want to change it.\n"
      else
        messages << "Your public holidays are not set. Call `set public holidays to COUNTRY/REGION` to set it.\n"
      end
      messages << "You have spent #{days_of_vacations} days of vacations in #{year} considering only weekdays.\n\n"
    else
      messages << "\n\n:large_yellow_square: weekend / :white_square: weekday / :white_small_square: not in month / :large_red_square: Public Holiday"
    end
    respond messages.join("\n")
  end
end
