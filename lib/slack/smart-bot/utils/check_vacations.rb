class SlackSmartBot
  def check_vacations(date: Date.today, user: nil, set_status: true, only_first_day: true)
    get_vacations()
    if user.nil?
      users = @vacations.keys
    else
      users = [user]
    end
    on_vacation = []    
    
    users.each do |user|
      type = nil
      expiration = nil

      if date.nil?
        if @vacations.key?(user) and @vacations[user][:public_holidays].to_s != ""
          country_region = @vacations[user][:public_holidays].downcase
        elsif config[:public_holidays].key?(:default_calendar)
          country_region = config[:public_holidays][:default_calendar].downcase
        else
          country_region = ''
        end
    
        local_day_time = local_time(country_region)
        if local_day_time.nil?
          date = Date.today
        else
          date = local_day_time.to_date
        end
      end
      @vacations[user].periods ||= []
      @vacations[user].periods.each do |p|
        if only_first_day and p.from == date.strftime("%Y/%m/%d")
          type = p.type
          on_vacation << user
          expiration = p.to
          break
        elsif !only_first_day and p.from <= date.strftime("%Y/%m/%d") and p.to >= date.strftime("%Y/%m/%d")
          type = p.type
          on_vacation << user
          expiration = p.to
          break
        end
      end
      unless type.nil? or !set_status
        icon = ''
        if type == 'vacation'
          icon = ':palm_tree:'
        elsif type == 'sick'
          icon = ':face_with_thermometer:'
        elsif type == 'sick child'
          icon = ':baby:'
        end
        unless icon.empty?
          expiration_date = Date.parse(expiration,'%Y/%m/%d') + 1 #next day at 0:00
          set_status(@vacations[user].user_id, status: icon, expiration: expiration_date, message: "#{type} until #{expiration}")
        end
      end
    end
    return on_vacation
  end
end
