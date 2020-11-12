class SlackSmartBot
  # help: ----------------------------------------------
  # help: `delete repl SESSION_NAME`
  # help: `delete irb SESSION_NAME`
  # help: `remove repl SESSION_NAME`
  # help: 
  # help:     Will delete the specified REPL
  # help:     Only the creator of the REPL or an admin can delete REPLs
  # help:
  def delete_repl(dest, user, session_name)
    #todo: add tests
    save_stats(__method__)
    if config[:allow_access].key?(__method__) and !config[:allow_access][__method__].include?(user.name) and !config[:allow_access][__method__].include?(user.id) and 
      (!user.key?(:enterprise_user) or ( user.key?(:enterprise_user) and !config[:allow_access][__method__].include?(user[:enterprise_user].id)))
      respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
    else
      if @repls.key?(session_name)
        Dir.mkdir("#{config.path}/repl") unless Dir.exist?("#{config.path}/repl")
        if config.admins.include?(user.name) or @repls[session_name].creator_name == user.name
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
