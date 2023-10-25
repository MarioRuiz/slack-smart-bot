class SlackSmartBot
  def see_vacations(user, dest, from_user: '', add_stats: true, year: '')
    save_stats(__method__) if add_stats

    get_vacations()
    
    from_user_name = ''
    
    if from_user.empty?
      from_user_name = user.name
    else
      @users = get_users() if @users.empty?
      user_info = @users.select{|u| u.id == from_user or (u.key?(:enterprise_user) and u.enterprise_user.id == from_user)}[-1]
      from_user_name = user_info.name
    end

    if @vacations.key?(from_user_name) and @vacations[from_user_name][:public_holidays].to_s != ""
      country_region = @vacations[from_user_name][:public_holidays].downcase
    elsif config[:public_holidays].key?(:default_calendar)
      country_region = config[:public_holidays][:default_calendar].downcase
    else
      country_region = ''
    end

    local_day_time = local_time(country_region)
    if local_day_time.nil?
      today = Date.today
    else
      today = local_day_time.to_date
    end
    year = today.year if year.to_s == ''

    from_user = '' if from_user_name == user.name
    if !@vacations.key?(from_user_name) or !@vacations[from_user_name].key?(:periods) or @vacations[from_user_name].periods.empty?
      if from_user.empty?
        display_calendar(from_user_name, year) if dest[0] == 'D'
        respond "You didn't add any time off yet. Use `add vacation from YYYY/MM/DD to YYYY/MM/DD`"
      else
        respond "No time off added yet for <@#{from_user}>"
      end
    else
      messages = []
      messages << "*Time off <@#{from_user}> #{year}*" if !from_user.empty?
      
      display_calendar(from_user_name, year) if from_user_name == user.name and dest[0] == 'D'

      today_txt = today.strftime("%Y/%m/%d")
      current_added = false
      past_added = false
      @vacations[from_user_name].periods.sort_by { |v| v[:from]}.reverse.each do |vac|
        if !current_added and vac.to >= today_txt 
          messages << "*Current and future periods*" 
          current_added = true
        end
        if !past_added and vac.to < today_txt and from_user.empty? and vac.to[0..3] == year
          if dest[0]=='D'
            messages << "\n*Past periods #{year}*" 
            past_added = true
          else
            messages << "To see past periods call me from a DM"
            break
          end
        end
        unless !from_user.empty? and vac.to < today_txt
          if vac.to[0..3] == year
            if !from_user.empty?
              icon = ":beach_with_umbrella:"
            elsif vac.type == 'vacation'
              icon = ':palm_tree:'
            elsif vac.type == 'sick'
              icon = ':face_with_thermometer:'
            elsif vac.type == 'sick child'
              icon = ':baby:'
            end
            if vac.from == vac.to
              messages << "     #{icon}    #{vac.from}   ##{vac.vacation_id}"
            else
              messages << "     #{icon}    #{vac.from} -> #{vac.to}   ##{vac.vacation_id}"
            end
          end
        end
      end
      if !past_added and !current_added and dest[0]=='D' 
        if from_user.empty?
          messages << "No time off added yet for #{year}"
        else
          messages << "Not possible to see past periods for another user"
        end
      elsif !past_added and dest[0]=='D' and !from_user.empty? and from_user_name != user.name
        messages << "Not possible to see past periods for another user"
      end
      respond messages.join("\n")
    end
  end
end
