class SlackSmartBot
  def get_team_members(team)
    assigned_members = team.members.values.flatten
    assigned_members.uniq!
    assigned_members.dup.each do |m|
      user_info = @users.select { |u| u.id == m or (u.key?(:enterprise_user) and u.enterprise_user.id == m) or u.name == m or (u.key?(:enterprise_user) and u.enterprise_user.name == m) }[-1]
      assigned_members.delete(m) if user_info.nil? or user_info.deleted
    end
    channels_members = []
    all_team_members = assigned_members.dup
    if team.channels.key?("members")
      team_members = []
      team.channels["members"].each do |ch|
        get_channels_name_and_id() unless @channels_id.key?(ch)
        tm = get_channel_members(@channels_id[ch])
        if tm.nil?
          respond ":exclamation: Add the Smart Bot to *##{ch}* channel to be able to get the list of members.", dest
        else
          channels_members << @channels_id[ch]
          tm.each do |m|
            user_info = @users.select { |u| u.id == m or (u.key?(:enterprise_user) and u.enterprise_user.id == m) }[-1]
            team_members << user_info.name unless user_info.is_app_user or user_info.is_bot
          end
        end
      end
      team_members.flatten!
      team_members.uniq!
      unassigned_members = team_members - assigned_members
      unassigned_members.delete(config.nick)
      not_on_team_channel = assigned_members - team_members
      all_team_members += team_members
    else
      unassigned_members = []
      not_on_team_channel = []
    end

    return assigned_members, unassigned_members, not_on_team_channel, channels_members, all_team_members
  end
end
