class SlackSmartBot
  def personal_settings(user, type, settings_id, settings_value)
    save_stats "#{type}_personal_settings"
    if Thread.current[:typem] == :on_dm
      get_personal_settings()
      @personal_settings[user.name] ||= {}
      if type == :get
        if @personal_settings[user.name].key?(settings_id)
          respond "Personal settings for *#{settings_id}* is: *#{@personal_settings[user.name][settings_id]}*."
        else
          respond "Personal settings for *#{settings_id}* not found."
        end
      elsif type == :delete
        if @personal_settings[user.name].key?(settings_id)
          @personal_settings[user.name].delete(settings_id)
          update_personal_settings()
          respond "Personal settings deleted for *#{settings_id}*."
        else
          respond "Personal settings for *#{settings_id}* not found."
        end
      else #set
        @personal_settings[user.name][settings_id] = settings_value
        update_personal_settings()
        respond "Personal settings set for *#{settings_id}*."
      end
    else
      respond "This command can only be called on a DM with the SmartBot."
    end
  end
end
