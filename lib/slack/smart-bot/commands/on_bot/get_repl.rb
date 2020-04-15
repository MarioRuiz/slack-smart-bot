class SlackSmartBot
  # help: ----------------------------------------------
  # help: `get repl SESSION_NAME`
  # help: `get irb SESSION_NAME`
  # help: `get live SESSION_NAME`
  # help: 
  # help:     Will get the Ruby commands sent on that SESSION_NAME.
  # help:
  def get_repl(dest, user, session_name)
    #todo: add tests
    save_stats(__method__)
    if config[:allow_access].key?(__method__) and !config[:allow_access][__method__].include?(user.name) and !config[:allow_access][__method__].include?(user.id) and 
      (!user.key?(:enterprise_user) or ( user.key?(:enterprise_user) and !config[:allow_access][__method__].include?(user[:enterprise_user].id)))
      respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
    else
      Dir.mkdir("#{config.path}/repl") unless Dir.exist?("#{config.path}/repl")
      Dir.mkdir("#{config.path}/repl/#{@channel_id}") unless Dir.exist?("#{config.path}/repl/#{@channel_id}")
      if File.exist?("#{config.path}/repl/#{@channel_id}/#{session_name}.run")
        if @repls.key?(session_name) and @repls[session_name][:type] == :private and 
          @repls[session_name][:creator_name]!=user.name and 
          !config.admins.include?(user.name)
          respond "The REPL with session name: #{session_name} is private", dest
        else
          if @repls.key?(session_name)
            @repls[session_name][:accessed] = Time.now.to_s
            @repls[session_name][:gets] += 1
            update_repls()
          end

          content = "require 'nice_http'\n"
          if File.exist?("#{project_folder}/.smart-bot-repl")
            content += File.read("#{project_folder}/.smart-bot-repl")
            content += "\n"
          end
          content += File.read("#{config.path}/repl/#{@channel_id}/#{session_name}.run").gsub(/^(quit|exit|bye)$/i,'') #todo: remove this gsub it will never contain it
          File.write("#{config.path}/repl/#{@channel_id}/#{session_name}.rb", content, mode: "w+")
          send_file(dest, "REPL #{session_name} on #{config.channel}", "#{config.path}/repl/#{@channel_id}/#{session_name}.rb", " REPL #{session_name} on #{config.channel}", 'text/plain', "ruby")
        end
      else
        respond "The REPL with session name: #{session_name} doesn't exist on this Smart Bot Channel", dest
      end
    end
  end
end
