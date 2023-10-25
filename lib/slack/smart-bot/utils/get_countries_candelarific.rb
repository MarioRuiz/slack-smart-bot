class SlackSmartBot
  def get_countries_candelarific()
    http = NiceHttp.new("#{config[:public_holidays][:host]}/api/v2")
    if File.exist?("#{config.path}/vacations/countries_candelarific.json")
      @countries_candelarific = JSON.parse(File.read("#{config.path}/vacations/countries_candelarific.json"))
    else
      response = http.get "/countries?api_key=#{config[:public_holidays][:api_key]}"
      countries_candelarific = response.data.json(:countries)
      if countries_candelarific.is_a?(Array)
        File.write("#{config.path}/vacations/countries_candelarific.json", countries_candelarific.to_json)
        @countries_candelarific = JSON.parse(countries_candelarific.to_json)
      else
        @countries_candelarific = []
      end
    end
    http.close
  end
end
