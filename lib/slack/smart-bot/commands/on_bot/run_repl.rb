class SlackSmartBot
  # help: ----------------------------------------------
  # help: `run repl SESSION_NAME`
  # help: `run repl SESSION_NAME ENV_VAR=VALUE ENV_VAR=VALUE`
  # help: `run live SESSION_NAME`
  # help: `run irb SESSION_NAME`
  # help:     Will run the repl session specified and return the output. 
  # help:     You can supply the Environmental Variables you need for the Session
  # help:     It will return only the values that were print out on the repl with puts, print, p or pp
  # help:     Example:
  # help:       _run repl CreateCustomer LOCATION=spain HOST='https://10.30.40.50:8887'_
  # help:
  def run_repl(dest, user, session_name, env_vars, rules_file)
    #todo: add tests
    from = user.name
    if config[:allow_access].key?(__method__) and !config[:allow_access][__method__].include?(user.name) and !config[:allow_access][__method__].include?(user.id) and 
      (!user.key?(:enterprise_user) or ( user.key?(:enterprise_user) and !config[:allow_access][__method__].include?(user[:enterprise_user].id)))
      respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
    else
      save_stats(__method__)
      Dir.mkdir("#{config.path}/repl") unless Dir.exist?("#{config.path}/repl")
      Dir.mkdir("#{config.path}/repl/#{@channel_id}") unless Dir.exist?("#{config.path}/repl/#{@channel_id}")
      if File.exist?("#{config.path}/repl/#{@channel_id}/#{session_name}.run")
        if @repls.key?(session_name) and (@repls[session_name][:type] == :private or @repls[session_name][:type] == :private_clean) and 
          @repls[session_name][:creator_name]!=user.name and 
          !config.admins.include?(user.name)
          respond "The REPL with session name: #{session_name} is private", dest
        else
          if @repls.key?(session_name) #not temp
            @repls[session_name][:accessed] = Time.now.to_s
            if @repls[session_name].creator_name == user.name
              @repls[session_name][:runs_by_creator] += 1
            else
              @repls[session_name][:runs_by_others] += 1
            end
            update_repls()        
          end

          content = env_vars.join("\n")
          content += "\nrequire 'nice_http'\n"
          unless rules_file.empty? # to get the project_folder
            begin
              eval(File.new(config.path+rules_file).read) if File.exist?(config.path+rules_file)
            end
          end
          if File.exist?("#{project_folder}/.smart-bot-repl") and 
            ((@repls.key?(session_name) and @repls[session_name][:type] != :private_clean and @repls[session_name][:type] != :public_clean) or !@repls.key?(session_name))
            content += File.read("#{project_folder}/.smart-bot-repl")
            content += "\n"
          end
          content += File.read("#{config.path}/repl/#{@channel_id}/#{session_name}.run").gsub(/^(quit|exit|bye)$/i,'') #todo: remove this gsub, it will never contain it
          Dir.mkdir("#{project_folder}/tmp") unless Dir.exist?("#{project_folder}/tmp")
          Dir.mkdir("#{project_folder}/tmp/repl") unless Dir.exist?("#{project_folder}/tmp/repl")
          File.write("#{project_folder}/tmp/repl/#{session_name}.rb", content, mode: "w+")
          process_to_run = "ruby  ./tmp/repl/#{session_name}.rb"
          process_to_run = ("cd #{project_folder} && #{process_to_run}") if defined?(project_folder)
          respond "Running REPL #{session_name}"
          stdout, stderr, status = Open3.capture3(process_to_run)
          if stderr == ""
            if stdout == ""
              respond "*#{session_name}*: Nothing returned."
            else
              if stdout.to_s.lines.count < 60 and stdout.to_s.size < 3500
                respond "*#{session_name}*: #{stdout}"
              else
                send_file(dest, "", 'response.rb', "", 'text/plain', "ruby", content: stdout)
              end
            end
          else
            if (stdout.to_s+stderr.to_s).lines.count < 60
              respond "*#{session_name}*: #{stdout} #{stderr}"
            else
              send_file(dest, "", 'response.rb', "", 'text/plain', "ruby", content: (stdout.to_s+stderr.to_s))
            end

          end
        end
      else
        respond "The REPL with session name: #{session_name} doesn't exist on this Smart Bot Channel", dest
      end
    end
  end
end
