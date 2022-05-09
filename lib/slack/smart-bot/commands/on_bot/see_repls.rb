class SlackSmartBot
  # help: ----------------------------------------------
  # help: `see repls`
  # help: `see irbs`
  # help:     It will display the repls
  # help:     <https://github.com/MarioRuiz/slack-smart-bot#repl|more info>
  # help: command_id: :see_repls
  # help:
  def see_repls(dest, user, typem)
    #todo: add tests
    save_stats(__method__)
    from = user.name
    if has_access?(__method__, user)
      message = ""
      @repls.sort.to_h.each do |session_name, repl|
        if (repl.creator_name == user.name or repl.type == :public or repl.type == :public_clean) or (is_admin?(user.name) and typem == :on_dm)
          message += "(#{repl.type}) *#{session_name}*: #{repl.description} / created: #{repl.created} / accessed: #{repl.accessed} / creator: #{repl.creator_name} / runs: #{repl.runs_by_creator+repl.runs_by_others} / gets: #{repl.gets} \n"
        end
      end
      message = "No repls created" if message == ''
      respond message
    end
  end
end
