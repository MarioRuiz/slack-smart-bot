class SlackSmartBot
  def personal_settings(user, type, settings_id, settings_value)
    save_stats "#{type}_personal_settings"
    if Thread.current[:typem] == :on_dm
      user_name = user.name
      team_id = user.team_id
      team_id_user = team_id + "_" + user_name
      get_personal_settings()
      @personal_settings[team_id_user] ||= {}
      if type == :get
        if settings_id.to_s == ''
          personal_settings_txt = ""
          @personal_settings[team_id_user].each do |key, value|
            personal_settings_txt << "`#{key}`:  #{value}\n"
          end
          if personal_settings_txt == ""
            personal_settings_txt = "No personal settings found.\nYou can set personal settings with `set personal settings SETTINGS_ID VALUE`"
          end
          respond "Personal settings for *#{user.name}* are:\n#{personal_settings_txt}"
        else
          if @personal_settings[team_id_user].key?(settings_id)
            respond "Personal settings for *#{settings_id}* is: *#{@personal_settings[team_id_user][settings_id]}*."
          else
            respond "Personal settings for *#{settings_id}* not found."
          end
        end
      elsif type == :delete
        if @personal_settings[team_id_user].key?(settings_id)
          @personal_settings[team_id_user].delete(settings_id)
          update_personal_settings()
          respond "Personal settings deleted for *#{settings_id}*."
        else
          settings_id_deleted = []
          @personal_settings[team_id_user].each do |key, value|
            if key.match?(/^#{settings_id}\./i)
              @personal_settings[team_id_user].delete(key)
              settings_id_deleted << key
            end
          end
          if settings_id_deleted.empty?
            respond "Personal settings for *#{settings_id}* not found."
          else
            update_personal_settings()
            respond "Personal settings deleted for *#{settings_id}*:\n`#{settings_id_deleted.join("`, `")}`"
          end
        end
      else #set
        @personal_settings[team_id_user][settings_id] = settings_value
        update_personal_settings()
        respond "Personal settings set for *#{settings_id}*."
      end
    else
      respond "This command can only be called on a DM with the SmartBot."
    end
  end
end
