class SlackSmartBot
  def delete_team(user, team_name)
    save_stats(__method__) if answer.empty?

    if Thread.current[:dest][0] == "D"
      respond "This command cannot be called from a DM"
    else
      get_teams()
      if !@teams.key?(team_name.to_sym)
        respond "It seems like the team *#{team_name}* doesn't exist.\nRelated commands `add team TEAM_NAME PROPERTIES`, `see team TEAM_NAME`, `see teams`"
      elsif !(@teams[team_name.to_sym].members.values + [@teams[team_name.to_sym].creator] + config.masters).flatten.include?(user.name)
        respond "You have to be a member of the team, the creator or a Master admin to be able to delete this team."
      else
        if answer.empty?
          ask "do you really want to delete the #{team_name} team? (yes/no)"
        else
          case answer
          when /yes/i, /yep/i, /sure/i
            answer_delete
            @teams.delete(team_name.to_sym)
            update_teams()
            respond "The team #{team_name} has been deleted."
          when /no/i, /nope/i, /cancel/i
            answer_delete
            respond "Ok, the team was not deleted"
          else
            respond "I don't understand"
            ask "do you really want to delete the #{team_name} team? (yes/no)"  
          end
        end
      end
    end
  end
end
