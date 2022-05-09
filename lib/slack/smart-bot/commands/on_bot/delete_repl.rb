class SlackSmartBot
  # help: ----------------------------------------------
  # help: `delete repl SESSION_NAME`
  # help: `delete irb SESSION_NAME`
  # help: `remove repl SESSION_NAME`
  # help:     Will delete the specified REPL
  # help:     Only the creator of the REPL or an admin can delete REPLs
  # help:     <https://github.com/MarioRuiz/slack-smart-bot#repl|more info>
  # help: command_id: :delete_repl
  # help:
  def delete_repl(dest, user, session_name)
    #todo: add tests
    save_stats(__method__)
    if has_access?(__method__, user)
      if @repls.key?(session_name)
        Dir.mkdir("#{config.path}/repl") unless Dir.exist?("#{config.path}/repl")
        if is_admin?(user.name) or @repls[session_name].creator_name == user.name
          @repls.delete(session_name)
          update_repls()
          File.rename("#{config.path}/repl/#{@channel_id}/#{session_name}.input", "#{config.path}/repl/#{@channel_id}/#{session_name}_#{Time.now.strftime("%Y%m%d%H%M%S%N")}.deleted")
          File.delete("#{config.path}/repl/#{@channel_id}/#{session_name}.output") if File.exist?("#{config.path}/repl/#{@channel_id}/#{session_name}.output")
          File.delete("#{config.path}/repl/#{@channel_id}/#{session_name}.run") if File.exist?("#{config.path}/repl/#{@channel_id}/#{session_name}.run")
          respond "REPL #{session_name} deleted"
        else
          respond "Only admins or the creator of this REPL can delete it", dest
        end

      else
        respond "The REPL with session name: #{session_name} doesn't exist on this Smart Bot Channel", dest
      end
    end
  end
end
