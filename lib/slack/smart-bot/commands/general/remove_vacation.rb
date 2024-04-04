class SlackSmartBot
  def remove_vacation(user, vacation_id)
    save_stats(__method__)

    get_vacations()
    team_id_user = "#{user.team_id}_#{user.name}"

    if !@vacations.key?(team_id_user)
      respond "It seems like you don't have any time off added."
    elsif @vacations[team_id_user].periods.empty? or !@vacations[team_id_user].periods.vacation_id.include?(vacation_id)
      respond "It seems like the ID supplied doesn't exist. Please call `see my time off` and check the ID."
    else
      if @vacations.key?(team_id_user) and @vacations[team_id_user][:public_holidays].to_s != ""
        country_region = @vacations[team_id_user][:public_holidays].downcase
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

      vacations = @vacations[team_id_user].deep_copy
      vacation = vacations.periods.select {|v| v.vacation_id == vacation_id }[-1]
      vacations.periods.delete_if {|v| v.vacation_id == vacation_id }
      update_vacations({team_id_user => vacations})
      respond "Your time off has been removed."
      if vacation.from <= today.strftime("%Y/%m/%d") and vacation.to >= today.strftime("%Y/%m/%d")
        info = get_user_info(vacations.user_id)
        emoji = info.user.profile.status_emoji
        if (vacation.type == 'vacation' and emoji == ':palm_tree:') or (vacation.type == 'sick' and emoji == ':face_with_thermometer:') or
           (vacation.type == 'sick child' and emoji == ':baby:')
          set_status(vacations.user_id, status: '', expiration: '', message: '')
        end
        check_vacations(date: today, team_id: user.team_id, user: user.name, set_status: true, only_first_day: false)
      end
    end
  end
end
