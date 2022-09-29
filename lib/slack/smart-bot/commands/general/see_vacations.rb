class SlackSmartBot
  def see_vacations(user, from_user: '', add_stats: true)
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

    if !@vacations.key?(from_user_name) or @vacations[from_user_name].periods.empty?
      if from_user.empty?
        respond "You didn't add any time off yet. Use `add vacation from YYYY/MM/DD to YYYY/MM/DD`"
      else
        respond "No time off added yet for <@#{from_user}>"
      end
    else
      messages = []
      messages << "*Time off <@#{from_user}>*" if !from_user.empty?
      today = Date.today.strftime("%Y/%m/%d")
      current_added = false
      past_added = false
      @vacations[from_user_name].periods.sort_by { |v| v[:from]}.reverse.each do |vac|
        if !current_added and vac.to >= today
          messages << "*Current and future periods*" 
          current_added = true
        end
        if !past_added and vac.to < today and from_user.empty?
          messages << "\n*Past periods*" 
          past_added = true
        end
        unless !from_user.empty? and vac.to < today
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
      respond messages.join("\n")
    end
  end
end
