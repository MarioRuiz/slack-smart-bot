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
        respond "Public holidays for *#{country_region}* set."
        get_vacations()
        @vacations[user.name] ||= {}
        @vacations[user.name][:public_holidays] = country_region
        update_vacations()
    else
        respond "Be sure the country and state are correct."
    end
  end
end
