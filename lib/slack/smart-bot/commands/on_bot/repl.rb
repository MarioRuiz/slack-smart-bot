class SlackSmartBot
  # help: ----------------------------------------------
  # help: `repl`
  # help: `live`
  # help: `irb`
  # help: `repl SESSION_NAME`
  # help: `private repl SESSION_NAME`
  # help: `repl ENV_VAR=VALUE`
  # help: `repl SESSION_NAME ENV_VAR=VALUE ENV_VAR='VALUE'`
  # help: `repl SESSION_NAME: "DESCRIPTION"`
  # help: `repl SESSION_NAME: "DESCRIPTION" ENV_VAR=VALUE ENV_VAR='VALUE'`
  # help: 
  # help:     Will run all we write as a ruby command and will keep the session values. 
  # help:     SESSION_NAME only admits from a to Z, numbers, - and _
  # help:     If no SESSION_NAME supplied it will be treated as a temporary REPL
  # help:     If 'private' specified the repl will be accessible only by you and it will be displayed only to you when `see repls`
  # help:     To avoid a message to be treated, start the message with '-'.
  # help:     Send _quit_, _bye_ or _exit_ to finish the session.
  # help:     Send puts, print, p or pp if you want to print out something when using `run repl` later.
  # help:     After 30 minutes of no communication with the Smart Bot the session will be dismissed.
  # help:     If you declare on your rules file a method called `project_folder` returning the path for the project folder, the code will be executed from that folder. 
  # help:     By default it will be automatically loaded the gems: string_pattern, nice_hash and nice_http
  # help:     To pre-execute some ruby when starting the session add the code to .smart-bot-repl file on the project root folder defined on project_folder
  # help:     If you want to see the methods of a class or module you created use _ls TheModuleOrClass_
  # help:     You can supply the Environmental Variables you need for the Session
  # help:     Examples:
  # help:       _repl CreateCustomer LOCATION=spain HOST='https://10.30.40.50:8887'_
  # help:       _repl CreateCustomer: "It creates a random customer for testing" LOCATION=spain HOST='https://10.30.40.50:8887'_
  # help:       _repl delete_logs_
  # help:       _private repl random-ssn_
  # help:
  def repl(dest, user, session_name, env_vars, rules_file, command, description, type)
    #todo: add more tests
    from = user.name
    if config[:allow_access].key?(__method__) and !config[:allow_access][__method__].include?(user.name) and !config[:allow_access][__method__].include?(user.id) and 
      (!user.key?(:enterprise_user) or ( user.key?(:enterprise_user) and !config[:allow_access][__method__].include?(user[:enterprise_user].id)))
      respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
    else
      if !@repl_sessions.key?(from)
        save_stats(__method__)
        Dir.mkdir("#{config.path}/repl") unless Dir.exist?("#{config.path}/repl")
        Dir.mkdir("#{config.path}/repl/#{@channel_id}") unless Dir.exist?("#{config.path}/repl/#{@channel_id}")
        
        serialt = Time.now.strftime("%Y%m%d%H%M%S%N")
        if session_name.to_s==''
          session_name = "#{from}_#{serialt}"
          temp_repl = true
        else
          temp_repl = false
          i = 0
          name = session_name
          while File.exist?("#{config.path}/repl/#{@channel_id}/#{session_name}.input")
            i+=1
            session_name = "#{name}#{i}"
          end
        end
        @repl_sessions[from] = {
          name: session_name,
          dest: dest,
          started: Time.now,
          finished: Time.now,
          input: [],
          on_thread: Thread.current[:on_thread],
          thread_ts: Thread.current[:thread_ts]
        }

        unless temp_repl
          @repls[session_name] = {
              created: @repl_sessions[from][:started].to_s,
              accessed: @repl_sessions[from][:started].to_s,
              creator_name: user.name,
              creator_id: user.id,
              description: description,
              type: type,
              runs_by_creator: 0,
              runs_by_others: 0,
              gets: 0
          }
          update_repls()        
        end
    
        message = "Session name: *#{session_name}*
        From now on I will execute all you write as a Ruby command and I will keep the session open until you send `quit` or `bye` or `exit`. 
        I will respond with the result so it is not necessary you send `print`, `puts`, `p` or `pp` unless you want it as the output when calling `run repl`. 
        If you want to avoid a message to be treated by me, start the message with '-'. 
        After 30 minutes of no communication with the Smart Bot the session will be dismissed.
        If you want to see the methods of a class or module you created use _ls TheModuleOrClass_
        You can supply the Environmental Variables you need for the Session
        Example:
          _repl CreateCustomer LOCATION=spain HOST='https://10.30.40.50:8887'_
        "
        respond message, dest
        
        File.write("#{config.path}/repl/#{@channel_id}/#{@repl_sessions[from][:name]}.input", "", mode: "a+")
        File.write("#{config.path}/repl/#{@channel_id}/#{@repl_sessions[from][:name]}.output", "", mode: "a+")
        
        process_to_run = '
            ruby -e "' + env_vars.join("\n") + '
            require \"awesome_print\"
            bindme' + serialt + ' = binding
            eval(\"require \'nice_http\'\" , bindme' + serialt + ')

            file_input_repl = File.open(\"' + Dir.pwd + '/repl/' + @channel_id + '/' + session_name + '.input\", \"r\")
            while true do 
              sleep 0.2 
              if File.exist?(\"./.smart-bot-repl\")
                begin
                  eval(File.read(\"./.smart-bot-repl\"), bindme' + serialt + ')
                rescue Exception => resp_repl
                end
              end
              code_to_run_repl = file_input_repl.read
              if code_to_run_repl.to_s!=''
                if code_to_run_repl.to_s.match?(/^quit$/i) or 
                  code_to_run_repl.to_s.match?(/^exit$/i) or 
                  code_to_run_repl.to_s.match?(/^bye bot$/i) or
                  code_to_run_repl.to_s.match?(/^bye$/i)
                  exit
                else
                  if code_to_run_repl.match?(/^\s*ls\s+(.+)/)
                    code_to_run_repl = \"#{code_to_run_repl.scan(/^\s*ls\s+(.+)/).join}.methods - Object.methods\"
                  end
                  begin
                    code_to_run_repl.gsub!(/^\s*(puts|print|p|pp)\s/, \"\")
                    resp_repl = eval(code_to_run_repl.to_s, bindme' + serialt + ')
                  rescue Exception => resp_repl
                  end
                  if resp_repl.to_s != \"\"
                    open(\"' + Dir.pwd + '/repl/' + @channel_id + '/' + session_name + '.output\", \"a+\") {|f|
                      f.puts \"\`\`\`#{resp_repl.awesome_inspect}\`\`\`\"
                    }
                  end
                end
              end
            end"
        '

        unless rules_file.empty? # to get the project_folder
          begin
            eval(File.new(config.path+rules_file).read) if File.exist?(config.path+rules_file)
          end
        end
        started = Time.now
        process_to_run = ("cd #{project_folder} &&" + process_to_run) if defined?(project_folder)
        
        stdin, stdout, stderr, wait_thr = Open3.popen3(process_to_run)
        timeout = 30 * 60 # 30 minutes
        
        file_output_repl = File.open("#{config.path}/repl/#{@channel_id}/#{session_name}.output", "r")

        while (wait_thr.status == 'run' or wait_thr.status == 'sleep') and @repl_sessions.key?(from)
          begin
            if (Time.now-@repl_sessions[from][:finished]) > timeout
                open("#{config.path}/repl/#{@channel_id}/#{@repl_sessions[from][:name]}.input", 'a+') {|f|
                  f.puts 'quit'
                }
                respond "REPL session finished: #{@repl_sessions[from][:name]}", dest
                @repl_sessions.delete(from)
                break
            end
            sleep 0.2
            resp_repl = file_output_repl.read
            if resp_repl.to_s!=''
              respond resp_repl, dest
            end
          rescue Exception => excp
            @logger.fatal excp
          end
        end
      else
        @repl_sessions[from][:finished] = Time.now
        code = @repl_sessions[from][:command]
        @repl_sessions[from][:command] = ''
        code.gsub!("\\n", "\n")
        code.gsub!("\\r", "\r")
        # Disabled for the moment sinde it is deleting lines with '}'
        #code.gsub!(/^\W*$/, "") #to remove special chars from slack when copy/pasting.
        if code.match?(/System/i) or code.match?(/Kernel/i) or code.include?("File") or
          code.include?("`") or code.include?("exec") or code.include?("spawn") or code.include?("IO.") or
          code.match?(/open3/i) or code.match?(/bundle/i) or code.match?(/gemfile/i) or code.include?("%x") or
          code.include?("ENV") or code.match?(/=\s*IO/)
          respond "Sorry I cannot run this due security reasons", dest
        else
          @repl_sessions[from][:input]<<code
          case code
          when /^\s*(quit|exit|bye|bye bot)\s*$/i
            open("#{config.path}/repl/#{@channel_id}/#{@repl_sessions[from][:name]}.input", 'a+') {|f|
              f.puts code
            }
            respond "REPL session finished: #{@repl_sessions[from][:name]}", dest
            @repl_sessions.delete(from)
          when /^\s*-/i
            #ommit
          else
            open("#{config.path}/repl/#{@channel_id}/#{@repl_sessions[from][:name]}.input", 'a+') {|f|
              f.puts code
            }
          end
        end
      end
    end
  end
end
