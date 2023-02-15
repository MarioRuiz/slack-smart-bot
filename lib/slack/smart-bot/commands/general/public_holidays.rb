def public_holidays(country_name, location, year, month, day, add_stats: true, publish_results: true)
  save_stats(__method__) if add_stats
  if config[:public_holidays][:api_key].to_s == ""
    respond "Sorry, I don't have the API key for the public holidays #{config[:public_holidays][:host]}. Set it up on your SmartBot config file."
  else
    begin
      found_location = true
      http = NiceHttp.new("#{config[:public_holidays][:host]}/api/v2")
      if !defined?(@countries_candelarific)
        if File.exist?("#{config.path}/vacations/countries_candelarific.json")
          @countries_candelarific = JSON.parse(File.read("#{config.path}/vacations/countries_candelarific.json"))
        else
          response = http.get "/countries?api_key=#{config[:public_holidays][:api_key]}"
          countries_candelarific = response.data.json(:countries)
          if countries_candelarific.is_a?(Array)
            File.write("#{config.path}/vacations/countries_candelarific.json", countries_candelarific.to_json)
            @countries_candelarific = JSON.parse(countries_candelarific.to_json)
          else
            @countries_candelarific = []
          end
        end
      end
      country = @countries_candelarific.find { |c| c.country_name.match?(/^\s*#{country_name}\s*$/i) }
      if country.nil?
        respond "Country #{country_name} not found"
      else
        country_original_name = country_name.downcase
        country_region_id = country_name.downcase
        country_region_id += "/#{location.downcase}" unless location.empty?
        country_name = country["country_name"]
        country_iso = country["iso-3166"]
        states = []
        if @public_holidays.key?(country_region_id) and @public_holidays[country_region_id].key?(year.to_s)
          holidays = @public_holidays[country_region_id][year.to_s]
        elsif File.exist?(File.join(config.path, "vacations", "#{year}_#{country_region_id.gsub("/", "_").gsub(" ", "_")}.json"))
          holidays = (File.read(File.join(config.path, "vacations", "#{year}_#{country_region_id.gsub("/", "_").gsub(" ", "_")}.json"))).json()
        elsif !location.empty? and File.exist?(File.join(config.path, "vacations", "#{year}_#{country_original_name.gsub("/", "_").gsub(" ", "_")}.json"))
          holidays = (File.read(File.join(config.path, "vacations", "#{year}_#{country_original_name.gsub("/", "_").gsub(" ", "_")}.json"))).json()
          holidays.each do |holiday|
            if holiday.states.is_a?(Array)
              states << holiday.states.name
            else
              states << holiday.states
            end
          end
          holidays = holidays.select { |h| h.states.is_a?(String) and h.states == "All" or (h.states.is_a?(Array) and h.states.name.grep(/^\s*#{location}\s*$/i).length > 0) }
          holidays_specific = holidays.select { |h| h.states.is_a?(Array) and h.states.name.grep(/^\s*#{location}\s*$/i).length > 0 }
          found_location = false if holidays_specific.length == 0
        else
          response = http.get "/holidays?country=#{country_iso}&year=#{year}&day=#{day}&month=#{month}&api_key=#{config[:public_holidays][:api_key]}"
          holidays = response.data.json(:holidays)
          if location != ""
            holidays.each do |holiday|
              if holiday.states.is_a?(Array)
                states << holiday.states.name
              else
                states << holiday.states
              end
            end
            holidays = holidays.select { |h| h.states.is_a?(String) and h.states == "All" or (h.states.is_a?(Array) and h.states.name.grep(/^\s*#{location}\s*$/i).length > 0) }
            holidays_specific = holidays.select { |h| h.states.is_a?(Array) and h.states.name.grep(/^\s*#{location}\s*$/i).length > 0 }
            found_location = false if holidays_specific.length == 0
          end
          if day == "" and month == "" and holidays.is_a?(Array) and holidays.length > 0 and found_location
            File.write(File.join(config.path, "vacations", "#{year}_#{country_region_id.gsub("/", "_").gsub(" ", "_")}.json"), holidays.to_json) if holidays.is_a?(Array)
          end
        end
        if day == "" and month == ""
          date = year
        elsif day == ""
          date = "#{year}-#{"%02d" % month}"
        else
          date = "#{year}-#{"%02d" % month}-#{"%02d" % day}"
        end

        if holidays.is_a?(Array) and holidays.length > 0 and found_location
          date_holiday = ""
          messages = ["*Holidays in #{country_name}#{" #{location.downcase.capitalize}" unless location.empty?} in #{date}*"]
          num_holidays_to_show = 0
          all_holidays = []
          states = []
          holidays_to_add = []
          holidays.each do |holiday|
            if holiday.type.join.match?(/holiday/i)
              if location == "" or (location != "" and (holiday.states.is_a?(String) and holiday.states == "All") or (holiday.states.is_a?(Array) and holiday.states.name.grep(/#{location}/i).length > 0))
                holiday_id = "#{holiday[:date][:datetime][:year]}-#{"%02d" % holiday[:date][:datetime][:month]}-#{"%02d" % holiday[:date][:datetime][:day]} #{holiday[:name]}"
                unless all_holidays.include?(holiday_id) or
                       (day != "" and holiday[:date][:datetime][:day] != day.to_i) or
                       (month != "" and holiday[:date][:datetime][:month] != month.to_i)
                  all_holidays << holiday_id
                  if day == ""
                    m = holiday[:date][:datetime][:month]
                    d = holiday[:date][:datetime][:day]
                    date_holiday = " #{holiday[:date][:datetime][:year]}-#{"%02d" % m}-#{"%02d" % d} "
                  end
                  num_holidays_to_show += 1
                  break if num_holidays_to_show > 30 and publish_results
                  week_day = Date.new(holiday[:date][:datetime][:year], holiday[:date][:datetime][:month], holiday[:date][:datetime][:day]).strftime("%A")
                  messages << "\t:spiral_calendar_pad:#{date_holiday}*#{holiday[:name]}* _(#{holiday[:type].join(", ")}) (#{week_day})_"
                  messages << "\t#{holiday[:description]}"
                  if location == ""
                    if holiday.states.is_a?(Array)
                      messages << "\tLocations: #{holiday.states.name.sort.join(", ")}"
                    else
                      messages << "\tLocations: #{holiday.states}"
                    end
                  end
                  if holiday.states.is_a?(Array)
                    states << holiday.states.name
                  else
                    states << holiday.states
                  end
                  messages << "\n"
                  holidays_to_add << holiday
                end
              end
            end
          end
          @public_holidays[country_region_id] = {} if !@public_holidays.key?(country_region_id)
          @public_holidays[country_region_id][year.to_s] = holidays_to_add if !@public_holidays[country_region_id].key?(year.to_s)

          if num_holidays_to_show > 30
            messages = ["*Holidays in #{country_name}#{" #{location.downcase.capitalize}" unless location.empty?} in #{date}*"]
            messages << "Too many holidays to show, please refine your search"
          end
        else
          messages = ["*No holidays found in #{country_name}#{" #{location.downcase.capitalize}" unless location.empty?} in #{date}. Be sure the Country and State are written correctly. Try using just the Country, not all countries are supporting States.*"]
        end
        states.flatten!
        states.uniq!
        states.delete("All")
        if states.length > 1 and (location == "" or !found_location)
          messages << "*All States found in #{date} #{country_name}*: #{states.sort.join(", ")}"
          respond messages[-1] if !publish_results
        end
        respond messages.join("\n") unless !publish_results
      end
    rescue Exception => stack
      respond "Sorry, I can't get the public holidays for #{country_name} #{location} in #{date}. Error: #{stack.message}"
      @logger.fatal stack
    end
    return (found_location==true and !country.nil?) if !publish_results
  end
end
