class SlackSmartBot
  def update_team(user, team_name, new_name: "", new_info: "", delete_opts: "", add_opts: "")
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
      respond "It seems like the team *#{team_name}* doesn't exist.\nRelated commands `add team TEAM_NAME PROPERTIES`, `see team TEAM_NAME`, `see teams`"
    elsif !(all_team_members + [@teams[team_name.to_sym].creator] + config.masters).flatten.include?(user.name)
      respond "You have to be a member of the team, the creator or a Master admin to be able to update this team."
    else
      wrong = false
      if new_name != ""
        team = @teams[team_name.to_sym].deep_copy
        @teams[new_name.to_sym] = team
        @teams.delete(team_name.to_sym)
        File.delete(File.join(config.path, "teams", "t_#{team_name}.yaml"))
        message = "The *#{team_name}* team has been renamed #{new_name}."
        team_name = new_name
      elsif new_info != ""
        @teams[team_name.to_sym].info = new_info
      elsif delete_opts != ""
        last_type = nil
        delete_opts.split(" ").each do |opt|
          if opt.match?(/^\s*$/)
            #blank
          elsif opt.match?(/^[\w\-]+$/i)
            last_type = opt
          elsif opt.match(/<?@(\w+)>?/i) #accepts also @username for the case the user has been deactivated
            member_id = $1
            member_info = @users.select { |u| u.id == member_id or u.name == member_id or (u.key?(:enterprise_user) and u.enterprise_user.id == member_id) }[-1]
            if last_type.nil?
              @teams[team_name.to_sym].members.each do |type, members|
                @teams[team_name.to_sym].members[type].delete(member_info.name)
              end
            else
              @teams[team_name.to_sym].members[last_type] ||= []
              @teams[team_name.to_sym].members[last_type].delete(member_info.name)
            end
          elsif opt.match(/<#(\w+)\|[^>]*>/i)
            channel_id = $1
            get_channels_name_and_id() unless @channels_name.keys.include?(channel_id)
            channel = @channels_name[channel_id]
            if last_type.nil?
              @teams[team_name.to_sym].channels.each do |type, channels|
                @teams[team_name.to_sym].channels[type].delete(channel)
              end
            else
              @teams[team_name.to_sym].channels[last_type] ||= []
              @teams[team_name.to_sym].channels[last_type].delete(channel)
            end
          else
            respond "It seems like the members or channel list is not correct. Please double check."
            wrong = true
            break
          end
        end
        tmembers = @teams[team_name.to_sym].members.deep_copy
        tmembers.each do |type, members|
          @teams[team_name.to_sym].members.delete(type) if members.empty?
        end
        tchannels = @teams[team_name.to_sym].channels.deep_copy
        tchannels.each do |type, channels|
          @teams[team_name.to_sym].channels.delete(type) if channels.empty?
        end
      elsif add_opts != ""
        last_type = nil
        add_opts.split(" ").each do |opt|
          if opt.match?(/^\s*$/)
            #blank
          elsif opt.match?(/^[\w\-]+$/i)
            last_type = opt
          elsif opt.match(/<@(\w+)>/i)
            member_id = $1
            last_type = 'no_type' if last_type.nil?
            member_info = @users.select { |u| u.id == member_id or (u.key?(:enterprise_user) and u.enterprise_user.id == member_id) }[-1]
            @teams[team_name.to_sym].members[last_type] ||= []
            @teams[team_name.to_sym].members[last_type] << member_info.name
            @teams[team_name.to_sym].members[last_type].uniq!
          elsif opt.match(/<#(\w+)\|[^>]*>/i)
            channel_id = $1
            get_channels_name_and_id() unless @channels_name.keys.include?(channel_id)
            channel = @channels_name[channel_id]
            @teams[team_name.to_sym].channels[last_type] ||= []
            @teams[team_name.to_sym].channels[last_type] << channel
            @teams[team_name.to_sym].channels[last_type].uniq!
          else
            respond "It seems like the members or channel list is not correct. Please double check."
            wrong = true
            break
          end
        end
        tmembers = @teams[team_name.to_sym].members.deep_copy
        tmembers.each do |type, members|
          @teams[team_name.to_sym].members.delete(type) if members.empty?
        end
        tchannels = @teams[team_name.to_sym].channels.deep_copy
        tchannels.each do |type, channels|
          @teams[team_name.to_sym].channels.delete(type) if channels.empty?
        end
      end
      unless wrong
        message ||= "The *#{team_name}* team has been updated."
        @teams[team_name.to_sym].status = :updated
        @teams[team_name.to_sym].user = user.name
        @teams[team_name.to_sym].date = Time.now.strftime("%Y-%m-%dT%H:%M:%S.000Z")[0..18]
        update_teams()
      end
      respond message
      see_teams(user, team_name, add_stats: false) unless wrong
    end
  end
end
