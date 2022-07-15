class SlackSmartBot
  def add_memo_team(user, privacy, team_name, topic, type, message)
    save_stats(__method__)

    get_teams()
    if @teams.key?(team_name.to_sym)
      assigned_members = @teams[team_name.to_sym].members.values.flatten
      assigned_members.uniq!
      all_team_members = assigned_members.dup
      team_members = []
      if @teams[team_name.to_sym].channels.key?("members")
        @teams[team_name.to_sym].channels["members"].each do |ch|
          get_channels_name_and_id() unless @channels_id.key?(ch)
          tm = get_channel_members(@channels_id[ch])
          tm.each do |m|
            user_info = @users.select { |u| u.id == m or (u.key?(:enterprise_user) and u.enterprise_user.id == m) }[-1]
            team_members << user_info.name unless user_info.is_app_user or user_info.is_bot
          end
        end
      end
      team_members.flatten!
      team_members.uniq!
      all_team_members += team_members
      all_team_members.uniq!
    end

    if !@teams.key?(team_name.to_sym)
      respond "It seems like the team *#{team_name}* doesn't exist\nRelated commands `add team TEAM_NAME PROPERTIES`, `see team TEAM_NAME`, `see teams`"
    elsif !(all_team_members + config.masters).flatten.include?(user.name)
      respond "You have to be a member of the team or a Master admin to be able to add a memo to the team."
    else
      topic = :no_topic if topic == ''
      @teams[team_name.to_sym][:memos] ||= []
      if @teams[team_name.to_sym][:memos].empty?
        memo_id = 1
      else
        memo_id = @teams[team_name.to_sym][:memos].memo_id.flatten.max + 1
      end
      @teams[team_name.to_sym][:memos] << {
        memo_id: memo_id,
        topic: topic,
        type: type,
        privacy: privacy,
        user: user.name,
        date: Time.now.strftime("%Y-%m-%dT%H:%M:%S.000Z")[0..18],
        message: message
      }
      update_teams()
      respond "The memo has been added to *#{team_name}* team."
      see_teams(user, team_name, add_stats: false)
    end
  end
end
