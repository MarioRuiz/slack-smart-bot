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
      vacations.periods.delete_if {|v| v.vacation_id == vacation_id }
      update_vacations({user.name => vacations})
      respond "Your time off has been removed."
    end
  end
end
