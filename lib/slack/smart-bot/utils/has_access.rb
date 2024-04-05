class SlackSmartBot
  def has_access?(method, user = nil)
    user = Thread.current[:user] if user.nil?
    team_id_user = "#{user.team_id}_#{user.name}"
    if config[:allow_access].key?(method) and !config[:allow_access][method].include?(user.name) and !config[:allow_access][method].include?(user.id) and
      !config[:allow_access][method].include?(team_id_user) and
       (!user.key?(:enterprise_user) or (user.key?(:enterprise_user) and !config[:allow_access][method].include?(user[:enterprise_user].id) and
       !config[:allow_access][method].include?("#{user[:enterprise_user].enterprise_id}_#{user[:enterprise_user].name}")))
      respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
      return false
    else
      if Thread.current[:typem] == :on_call
        channel = Thread.current[:dchannel]
      elsif Thread.current[:using_channel].to_s == ""
        channel = Thread.current[:dest]
      else
        channel = Thread.current[:using_channel]
      end
      if !@access_channels.key?(channel) or !@access_channels[channel].key?(method.to_s) or
        @access_channels[channel][method.to_s].include?(user.name) or
        @access_channels[channel][method.to_s].include?(team_id_user)
        return true
      else
        if @admins_channels.key?(channel) and !@admins_channels[channel].empty?
            admins = @admins_channels[channel].map { |a| a.split('_')[1..-1].join('_') }
            respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{admins.join(">, <@")}>"
        else
            respond "You don't have access to use this command, please contact an Admin to be able to use it."
        end
        return false
      end
    end
  end
end
