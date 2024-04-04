class SlackSmartBot
  def set_public_holidays(country, state, user)
    save_stats(__method__)

    result = public_holidays(country, state, Date.today.year.to_s, '', '', add_stats: false, publish_results: false)
    if result == true
        team_id_user = "#{user.team_id}_#{user.name}"
        if state == ""
            country_region = country
        else
            country_region = "#{country}/#{state}"
        end
        if state == ''
          respond "Public holidays for *#{country_region}* set. If available States, try with the country and state to be more precise."
        else
          respond "Public holidays for *#{country_region}* set."
        end
        get_vacations()
        @vacations[team_id_user] ||= {}
        @vacations[team_id_user][:public_holidays] = country_region
        update_vacations()
        check_vacations(date: nil, team_id: user.team_id, user: user.name, set_status: true, only_first_day: false)
    else
        respond "Be sure the country and state are correct. If not displayed available states, try with the country only."
    end
  end
end
