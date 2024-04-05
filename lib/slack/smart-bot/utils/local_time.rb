class SlackSmartBot
  def local_time(country_region, return_default_if_not_found = true)
    require "tzinfo"
    @time_zone_identifiers ||= TZInfo::Timezone.all_identifiers
    country, region = country_region.to_s.split("/")
    identifier = nil
    if region.nil?        
      get_countries_candelarific() if !defined?(@countries_candelarific)  
      found_country = @countries_candelarific.find { |c| c.country_name.match?(/^\s*#{country}\s*$/i) }
      unless found_country.nil?
        country_iso = found_country["iso-3166"]
        found_country = TZInfo::Country.get(country_iso).zone_identifiers
        region = found_country.first.split("/").last unless found_country.empty?
      end
    end
    identifier = @time_zone_identifiers.find { |id| id.downcase.include?(region.to_s.gsub(" ", "_").downcase) } unless region.nil?
    identifier = @time_zone_identifiers.find { |id| id.downcase.include?(country.to_s.gsub(" ", "_").downcase) } if identifier.nil?
    if identifier.nil?
      if return_default_if_not_found
        return local_time(config.public_holidays.default_calendar, false)
      else
        return nil
      end
    else
      tz = TZInfo::Timezone.get(identifier)
      return tz.now
    end
  end
end
