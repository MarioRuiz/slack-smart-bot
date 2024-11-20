class SlackSmartBot
  def get_authorizations(session_name, team_id_user_creator)
    team_id_user = Thread.current[:team_id_user]

    authorizations = {}

    if config.key?(:authorizations)
      config[:authorizations].each do |key, value|
        if value.key?(:host)
          authorizations[value[:host]] = value
        end
      end
    end

    if @personal_settings_hash.key?(team_id_user) and @personal_settings_hash[team_id_user].key?(:authorizations)
      @personal_settings_hash[team_id_user][:authorizations].each do |key, value|
        if value.key?(:host)
          authorizations[value[:host]] = value
        end
      end
    end

    if !session_name.nil?
      if team_id_user != team_id_user_creator
        team_id_to_use = team_id_user_creator
      else
        team_id_to_use = team_id_user
      end
      if @open_ai[team_id_to_use][:chat_gpt][:sessions].key?(session_name) and
         @open_ai[team_id_to_use][:chat_gpt][:sessions][session_name].key?(:authorizations) and
         !@open_ai[team_id_to_use][:chat_gpt][:sessions][session_name][:authorizations].nil?
        @open_ai[team_id_to_use][:chat_gpt][:sessions][session_name][:authorizations].each do |host, header|
          authorizations[host] ||= {}
          authorizations[host].merge!(header)
        end
      end
    end

    return authorizations
  end
end
