class SlackSmartBot
  def remove_vacation(user, vacation_id)
    save_stats(__method__)

    get_vacations()
    if !@vacations.key?(user.name)
      respond "It seems like you don't have any time off added."
    elsif @vacations[user.name].periods.empty? or !@vacations[user.name].periods.vacation_id.include?(vacation_id)
      respond "It seems like the ID supplied doesn't exist. Please call `see my time off` and check the ID."
    else
      vacations = @vacations[user.name].deep_copy
      vacation = vacations.periods.select {|v| v.vacation_id == vacation_id }[-1]
      vacations.periods.delete_if {|v| v.vacation_id == vacation_id }
      update_vacations({user.name => vacations})
      respond "Your time off has been removed."
      if vacation.from <= Date.today.strftime("%Y/%m/%d") and vacation.to >= Date.today.strftime("%Y/%m/%d")
        info = get_user_info(vacations.user_id)
        emoji = info.user.profile.status_emoji
        if (vacation.type == 'vacation' and emoji == ':palm_tree:') or (vacation.type == 'sick' and emoji == ':face_with_thermometer:')
          set_status(vacations.user_id, status: '', expiration: '', message: '')
        end
        check_vacations(date: Date.today, user: user.name, set_status: true, only_first_day: false)
      end
    end
  end
end
