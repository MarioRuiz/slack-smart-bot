class SlackSmartBot
  # help: ----------------------------------------------
  # help: `kill repl RUN_REPL_ID`
  # help:     Will kill a running repl previously executed with 'run repl' command.
  # help:     Only the user that run the repl or a master admin can kill the repl.
  # help:  Example:
  # help:       _kill repl X33JK_
  # help:     <https://github.com/MarioRuiz/slack-smart-bot#repl|more info>
  # help: command_id: :kill_repl
  # help:
  def kill_repl(dest, user, repl_id)
    #todo: add tests
    if has_access?(__method__, user)
      save_stats(__method__)
      if !@run_repls.key?(repl_id)
        respond "The run repl with id #{repl_id} doesn't exist"
      elsif @run_repls[repl_id].user != user.name and !config.masters.include?(user.name)
        respond "Only #{@run_repls[repl_id].user} or a master admin can kill this repl."
      else
        pids = `pgrep -P #{@run_repls[repl_id].pid}`.split("\n").map(&:to_i) #todo: it needs to be adapted for Windows
        pids.each do |pd|
          begin
            Process.kill("KILL", pd)
          rescue
          end
        end
        respond "The repl #{@run_repls[repl_id].name} (id: #{repl_id}) has been killed."
        @run_repls.delete(repl_id)
      end
    end
  end
end
