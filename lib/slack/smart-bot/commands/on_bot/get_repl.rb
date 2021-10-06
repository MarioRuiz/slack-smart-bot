class SlackSmartBot
  # help: ----------------------------------------------
  # help: `get repl SESSION_NAME`
  # help: `get irb SESSION_NAME`
  # help: `get live SESSION_NAME`
  # help:     Will get the Ruby commands sent on that SESSION_NAME.
  # help:     <https://github.com/MarioRuiz/slack-smart-bot#repl|more info>
  # help:
  def get_repl(dest, user, session_name)
    #todo: add tests
    save_stats(__method__)
    if has_access?(__method__, user)
      Dir.mkdir("#{config.path}/repl") unless Dir.exist?("#{config.path}/repl")
      Dir.mkdir("#{config.path}/repl/#{@channel_id}") unless Dir.exist?("#{config.path}/repl/#{@channel_id}")
      if File.exist?("#{config.path}/repl/#{@channel_id}/#{session_name}.run")
        if @repls.key?(session_name) and (@repls[session_name][:type] == :private or @repls[session_name][:type] == :private_clean) and 
          @repls[session_name][:creator_name]!=user.name and 
          !is_admin?(user.name)
          respond "The REPL with session name: #{session_name} is private", dest
        else
          content = "require 'nice_http'\n"
          if @repls.key?(session_name)
            @repls[session_name][:accessed] = Time.now.to_s
            @repls[session_name][:gets] += 1
            update_repls()
          end
          if !@repls.key?(session_name) or 
            (File.exist?("#{project_folder}/.smart-bot-repl") and @repls[session_name][:type] != :private_clean and @repls[session_name][:type] != :public_clean)
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
