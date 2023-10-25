class SlackSmartBot

  def add_vacation(user, type, from, to)
    save_stats(__method__)
    get_vacations()
    from.gsub!('-','/')
    to.gsub!('-','/')
    if type.match?(/sick\s+baby/i) or type.match?(/sick\s+child/i)
      type = 'sick child'
    end

    if @vacations.key?(user.name) and @vacations[user.name][:public_holidays].to_s != ""
      country_region = @vacations[user.name][:public_holidays].downcase
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

    if from=='today'
      from = today.strftime("%Y/%m/%d")
    elsif from =='tomorrow'
      from = (today+1).strftime("%Y/%m/%d")
    elsif from.match?(/next\s+week/)
      from = today + ((8 - today.wday) % 7)
      from += 7 if from == today
      to = (from + 6).strftime("%Y/%m/%d")
      from = from.strftime("%Y/%m/%d")
    end

    to = from if to.empty?
    wrong = false
    begin
      from_date = Date.parse(from)
      to_date = Date.parse(to)
    rescue
      wrong = true
      respond "It seems like the date is not in the correct format: YYYY/MM/DD or is a wrong date."      
    end
    unless wrong
      if Date.parse(from).strftime("%Y/%m/%d") != from
        respond "It seems like the date #{from} is not in the correct format: YYYY/MM/DD or is a wrong date."
      elsif Date.parse(to).strftime("%Y/%m/%d") != to
        respond "It seems like the date #{to} is not in the correct format: YYYY/MM/DD or is a wrong date."
      else
        vacations = @vacations.deep_copy
        vacations[user.name] ||= { user_id: user.id, periods: [] }
        if !vacations[user.name].key?(:periods)
          vacations[user.name][:user_id] = user.id
          vacations[user.name][:periods] = []
        end

        if vacations[user.name].periods.empty?
          vacation_id = 1
        else
          vacation_id = vacations[user.name].periods[-1].vacation_id + 1
        end
        vacations[user.name].periods << { vacation_id: vacation_id, type: type.downcase, from: from, to: to }
        update_vacations({user.name => vacations[user.name]})
        respond "Period has been added   ##{vacation_id}"
        check_vacations(date: today, user: user.name, set_status: true, only_first_day: false)
      end
    end
  end
end
