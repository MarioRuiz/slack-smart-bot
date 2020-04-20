class SlackSmartBot
  # help: ----------------------------------------------
  # help: `see repls`
  # help: `see irbs`
  # help:    It will display the repls
  # help:
  def see_repls(dest, user, typem)
    #todo: add tests
    save_stats(__method__)
    from = user.name
    if config[:allow_access].key?(__method__) and !config[:allow_access][__method__].include?(user.name) and !config[:allow_access][__method__].include?(user.id) and 
      (!user.key?(:enterprise_user) or ( user.key?(:enterprise_user) and !config[:allow_access][__method__].include?(user[:enterprise_user].id)))
      respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
    else
      message = ""
      @repls.sort.to_h.each do |session_name, repl|
        if (repl.creator_name == user.name or repl.type == :public) or (config.admins.include?(user.name) and typem == :on_dm)
          message += "(#{repl.type}) *#{session_name}*: #{repl.description} / created: #{repl.created} / accessed: #{repl.accessed} / creator: <@#{repl.creator_name}> / runs: #{repl.runs_by_creator+repl.runs_by_others} / gets: #{repl.gets} \n"
        end
      end
      message = "No repls created" if message == ''
      respond message
    end
  end
end
