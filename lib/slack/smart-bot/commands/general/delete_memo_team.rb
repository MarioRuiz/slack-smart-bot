class SlackSmartBot
  def delete_memo_team(user, team_name, memo_id)
    save_stats(__method__) if answer.empty?

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
    elsif !(all_team_members + config.masters).flatten.include?(user.name)
      respond "You have to be a member of the team or a Master admin to be able to delete a memo of the team."
    elsif !@teams[team_name.to_sym].key?(:memos) or @teams[team_name.to_sym][:memos].empty? or !@teams[team_name.to_sym][:memos].memo_id.include?(memo_id.to_i)
      respond "It seems like there is no memo with id #{memo_id}"
    elsif @teams[team_name.to_sym][:memos].memo_id.include?(memo_id.to_i)
      memo_selected = @teams[team_name.to_sym][:memos].select { |m| m.memo_id == memo_id.to_i }[-1]
      if memo_selected.privacy == 'personal' and memo_selected.user != user.name
        respond "Only the creator can delete a personal memo."
      else
        if answer.empty?
          message = @teams[team_name.to_sym][:memos].select { |memo| memo.memo_id == memo_id.to_i }.message.join
          ask "do you really want to delete the memo #{memo_id} (#{message}) from #{team_name} team? (yes/no)"
        else
          case answer
          when /yes/i, /yep/i, /sure/i
            answer_delete
            memos = []
            message = ""
            get_teams()
            @teams[team_name.to_sym][:memos].each do |memo|
              if memo.memo_id != memo_id.to_i
                memos << memo
              else
                message = memo.message
              end
            end
            @teams[team_name.to_sym][:memos] = memos
            update_teams()
            respond "The memo has been deleted from team #{team_name}: #{message}"
          when /no/i, /nope/i, /cancel/i
            answer_delete
            respond "Ok, the memo was not deleted"
          else
            respond "I don't understand"
            ask "do you really want to delete the memo from #{team_name} team? (yes/no)"
          end
        end
      end
    end
  end
end
