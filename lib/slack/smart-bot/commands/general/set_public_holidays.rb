class SlackSmartBot
  def set_public_holidays(country, state, user)
    save_stats(__method__)

    result = public_holidays(country, state, Date.today.year.to_s, '', '', add_stats: false, publish_results: false)
    if result == true
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
        @vacations[user.name] ||= {}
        @vacations[user.name][:public_holidays] = country_region
        update_vacations()
        check_vacations(date: nil, user: user.name, set_status: true, only_first_day: false)
    else
        respond "Be sure the country and state are correct. If not displayed available states, try with the country only."
    end
  end
end
