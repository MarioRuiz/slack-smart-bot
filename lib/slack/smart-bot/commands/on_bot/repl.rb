class SlackSmartBot
  # help: ----------------------------------------------
  # help: `repl`
  # help: `live`
  # help: `irb`
  # help: `repl SESSION_NAME`
  # help: `private repl SESSION_NAME`
  # help: `clean repl SESSION_NAME`
  # help: `repl ENV_VAR=VALUE`
  # help: `repl SESSION_NAME ENV_VAR=VALUE ENV_VAR='VALUE'`
  # help: `repl SESSION_NAME: "DESCRIPTION"`
  # help: `repl SESSION_NAME: "DESCRIPTION" ENV_VAR=VALUE ENV_VAR='VALUE'`
  # help:     Will run all we write as a ruby command and will keep the session values. 
  # help:     SESSION_NAME only admits from a to Z, numbers, - and _
  # help:     If no SESSION_NAME supplied it will be treated as a temporary REPL
  # help:     If 'private' specified the repl will be accessible only by you and it will be displayed only to you when `see repls`
  # help:     If 'clean' specified the repl won't pre execute the code written on the .smart-bot-repl file
  # help:     To avoid a message to be treated, start the message with '-'.
  # help:     Send _quit_, _bye_ or _exit_ to finish the session.
  # help:     Send puts, print, p or pp if you want to print out something when using _run repl_ later.
  # help:     After 30 minutes of no communication with the Smart Bot the session will be dismissed.
  # help:     If you declare on your rules file a method called 'project_folder' returning the path for the project folder, the code will be executed from that folder. 
  # help:     By default it will be automatically loaded the gems: string_pattern, nice_hash and nice_http
  # help:     To pre-execute some ruby when starting the session add the code to .smart-bot-repl file on the project root folder defined on project_folder
  # help:     If you want to see the methods of a class or module you created use _ls TheModuleOrClass_
  # help:     You can supply the Environmental Variables you need for the Session
  # help:     You can add collaborators by sending _add collaborator @USER_ to the session.
  # help:     Examples:
  # help:       _repl CreateCustomer LOCATION=spain HOST='https://10.30.40.50:8887'_
  # help:       _repl CreateCustomer: "It creates a random customer for testing" LOCATION=spain HOST='https://10.30.40.50:8887'_
  # help:       _repl delete_logs_
  # help:       _private repl random-ssn_
  # help:     <https://github.com/MarioRuiz/slack-smart-bot#repl|more info>
  # help: command_id: :repl
  # help:
  def repl(dest, user, session_name, env_vars, rules_file, command, description, type)
    #todo: add more tests
    from = user.name
    if has_access?(__method__, user)
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
          thread_ts: Thread.current[:thread_ts],
          collaborators: [],
          user_type: :creator,
          user_creator: from
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
        react :running
        @ts_react ||= {}
        if Thread.current[:ts].to_s == ''
          @ts_react[session_name] = Thread.current[:thread_ts]
        else
          @ts_react[session_name] = Thread.current[:ts]
        end        
        @ts_repl ||= {}
        @ts_repl[session_name] = ''

        message = "Session name: *#{session_name}*
        From now on I will execute all you write as a Ruby command and I will keep the session open until you send `quit` or `bye` or `exit`. 
        In case you need someone to help you with the session you can add collaborators by sending `add collaborator @USER` to the session.
        I will respond with the result so it is not necessary you send `print`, `puts`, `p` or `pp` unless you want it as the output when calling `run repl`. 
        Use `p` to print a message raw, exacly like it is returned. 
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
        File.write("#{config.path}/repl/#{@channel_id}/#{@repl_sessions[from][:name]}.run", "", mode: "a+")
        
        if type != :private_clean and type != :public_clean
          pre_execute = '
            if File.exist?(\"./.smart-bot-repl\")
              begin
                eval(File.read(\"./.smart-bot-repl\"), bindme' + serialt + ')
              rescue Exception => resp_repl
              end
            end
          '
        else
          pre_execute = ''
        end

        process_to_run = '
            ' + env_vars.join("\n") + '
            require \"amazing_print\"
            require \"stringio\"
            bindme' + serialt + ' = binding
            eval(\"require \'nice_http\'\" , bindme' + serialt + ')
            def ls(obj)
              (obj.methods - Object.methods)
            end
            file_run_path = \"' +  + File.expand_path(config.path) + '/repl/' + @channel_id + '/' + session_name + '.rb\"
            file_input_repl = File.open(\"' + File.expand_path(config.path) + '/repl/' + @channel_id + '/' + session_name + '.input\", \"r\")
            ' + pre_execute + '
            while true do 
              sleep 0.2 
              code_to_run_repl = file_input_repl.read
              if code_to_run_repl.to_s!=\"\"
                add_to_run_repl = true
                if code_to_run_repl.to_s.match?(/^quit$/i) or 
                  code_to_run_repl.to_s.match?(/^exit$/i) or 
                  code_to_run_repl.to_s.match?(/^bye bot$/i) or
                  code_to_run_repl.to_s.match?(/^bye$/i)
                  exit
                else
                  if code_to_run_repl.match?(/^\s*ls\s+(.+)/)
                    add_to_run_repl = false
                  end
                  error = false
                  begin
                    begin
                      original_stdout = $stdout
                      $stdout = StringIO.new 
                      resp_repl = eval(code_to_run_repl, bindme' + serialt + ')
                      stdout_repl = $stdout.string
                    ensure 
                      $stdout = original_stdout
                    end
                  rescue Exception => resp_repl
                    error = true
                  end
                  if error
                    open(\"' + File.expand_path(config.path) + '/repl/' + @channel_id + '/' + session_name + '.output\", \"a+\") {|f|
                      f.puts \"\`\`\`\n#{resp_repl.to_s.gsub(/^.+' + session_name + '\.rb:\d+:/,\"\")}\`\`\`\"
                    }
                  else
                    if code_to_run_repl.match?(/^\s*p\s+/i)
                      resp_repl = stdout_repl unless stdout_repl.to_s == \'\'
                      if stdout_repl.to_s == \'\'
                        resp_repl = resp_repl.inspect
                      else
                        resp_repl = stdout_repl 
                      end
                      open(\"' + File.expand_path(config.path) + '/repl/' + @channel_id + '/' + session_name + '.output\", \"a+\") {|f|
                        f.puts \"\`\`\`\n#{resp_repl}\`\`\`\"
                      }
                    else
                      if stdout_repl.to_s == \'\'
                        resp_repl = resp_repl.ai
                      else
                        resp_repl = stdout_repl 
                      end
                      open(\"' + File.expand_path(config.path) + '/repl/' + @channel_id + '/' + session_name + '.output\", \"a+\") {|f|
                        f.puts \"\`\`\`\n#{resp_repl}\`\`\`\"
                      }
                    end
                    unless !add_to_run_repl
                      open(\"' + File.expand_path(config.path) + '/repl/' + @channel_id + '/' + session_name + '.run\", \"a+\") {|f|
                        f.puts code_to_run_repl
                      }
                    end
                  end
                end
              end
            end
        '
        unless rules_file.empty? # to get the project_folder
          begin
            eval(File.new(config.path+rules_file).read) if File.exist?(config.path+rules_file)
          end
        end
        process_to_run.gsub!('\"','"')
        file_run_path = "./tmp/repl/#{@channel_id}/#{session_name}.rb"
        if defined?(project_folder)
          Dir.mkdir("#{project_folder}/tmp/") unless Dir.exist?("#{project_folder}/tmp/")
          Dir.mkdir("#{project_folder}/tmp/repl") unless Dir.exist?("#{project_folder}/tmp/repl")
          Dir.mkdir("#{project_folder}/tmp/repl/#{@channel_id}/") unless Dir.exist?("#{project_folder}/tmp/repl/#{@channel_id}/")
          file_run = File.open(file_run_path.gsub('./',"#{project_folder}/"), "w")
          file_run.write process_to_run
          file_run.close
        else
          Dir.mkdir("./tmp/") unless Dir.exist?("./tmp/")
          Dir.mkdir("./tmp/repl") unless Dir.exist?("./tmp/repl")
          Dir.mkdir("./tmp/repl/#{@channel_id}/") unless Dir.exist?("./tmp/repl/#{@channel_id}/")
          file_run = File.open(file_run_path, "w")
          file_run.write process_to_run
          file_run.close
        end

        process_to_run = "ruby #{file_run_path}"

        started = Time.now
        process_to_run = ("cd #{project_folder} && " + process_to_run) if defined?(project_folder)
        stdin, stdout, stderr, wait_thr = Open3.popen3(process_to_run)
        timeout = 30 * 60 # 30 minutes
        
        file_output_repl = File.open("#{config.path}/repl/#{@channel_id}/#{session_name}.output", "r")
        @repl_sessions[from][:pid] = wait_thr.pid
        while (wait_thr.status == 'run' or wait_thr.status == 'sleep') and @repl_sessions.key?(from)
          begin
            if (Time.now-@repl_sessions[from][:finished]) > timeout
                open("#{config.path}/repl/#{@channel_id}/#{@repl_sessions[from][:name]}.input", 'a+') {|f|
                  f.puts 'quit'
                }
                respond "REPL session finished: #{@repl_sessions[from][:name]}", dest
                unreact :running, @ts_react[@repl_sessions[from].name]
                pids = `pgrep -P #{@repl_sessions[from][:pid]}`.split("\n").map(&:to_i) #todo: it needs to be adapted for Windows
                pids.each do |pid|
                  begin
                    Process.kill("KILL", pid)
                  rescue
                  end
                end
                @repl_sessions[from][:collaborators].each do |collaborator|
                  @repl_sessions.delete(collaborator)
                end  
                @repl_sessions.delete(from)
                break
            end
            sleep 0.2
            resp_repl = file_output_repl.read
            if resp_repl.to_s!=''
              if @ts_repl[@repl_sessions[from].name].to_s != ''
                unreact(:running, @ts_repl[@repl_sessions[from].name]) 
                @ts_repl[@repl_sessions[from].name] = ''
              end
              if resp_repl.to_s.lines.count < 60 and resp_repl.to_s.size < 3500
                respond resp_repl, dest
              else
                resp_repl.gsub!(/^\s*```/,'')
                resp_repl.gsub!(/```\s*$/,'')
                send_file(dest, "", 'response.rb', "", 'text/plain', "ruby", content: resp_repl)
              end
            end
          rescue Exception => excp
            @logger.fatal excp
          end
        end
      elsif @repl_sessions.key?(from) and @repl_sessions[from][:command].to_s == ''
        respond 'You are already in a repl on this SmartBot. You need to quit that one before starting a new one.'
      else
        @repl_sessions[from][:finished] = Time.now
        code = @repl_sessions[from][:command]
        @repl_sessions[from][:command] = ''
        code.gsub!("\\n", "\n")
        code.gsub!("\\r", "\r")
        # Disabled for the moment since it is deleting lines with '}'
        #code.gsub!(/^\W*$/, "") #to remove special chars from slack when copy/pasting.
        if code.match?(/System/i) or code.match?(/Kernel/i) or code.include?("File.") or
          code.include?("`") or code.include?("exec") or code.include?("spawn") or code.include?("IO.") or
          code.match?(/open3/i) or code.match?(/bundle/i) or code.match?(/gemfile/i) or code.include?("%x") or
          code.include?("ENV") or code.match?(/=\s*IO/) or code.include?("Dir.") or 
          code.match?(/=\s*File/) or code.match?(/=\s*Dir/) or code.match?(/<\s*File/) or code.match?(/<\s*Dir/) or
          code.match?(/\w+:\s*File/) or code.match?(/\w+:\s*Dir/) or 
          code.match?(/=?\s*(require|load)(\(|\s)/i)

          respond "Sorry I cannot run this due security reasons", dest
        elsif code.match(/\A\s*add\s+collaborator\s+<@(\w+)>\s*\z/i)
            collaborator = $1
            user_info = @users.select{|u| u.id == collaborator or (u.key?(:enterprise_user) and u.enterprise_user.id == collaborator)}[-1]
            collaborator_name = user_info.name
            if @repl_sessions.key?(collaborator_name)
              respond "Sorry, <@#{collaborator}> is already in a repl. Please ask her/him to quit it first.", dest
            else
              respond "Collaborator added. Now <@#{collaborator}> can interact with this repl.", dest
              creator = @repl_sessions[from][:user_creator]
              @repl_sessions[creator][:collaborators] << collaborator_name
              @repl_sessions[collaborator_name] = {
                name: @repl_sessions[from][:name],
                dest: dest,
                on_thread: Thread.current[:on_thread],
                thread_ts: Thread.current[:thread_ts],
                user_type: :collaborator,
                user_creator: creator
              }    
            end
        else
          if @repl_sessions[from][:user_type] == :collaborator
            @repl_sessions[@repl_sessions[from][:user_creator]][:input] << code
          else
            @repl_sessions[from][:input] << code
          end
          case code
          when /^\s*(quit|exit|bye|bye\s+bot)\s*$/i
            if @repl_sessions[from][:user_type] == :collaborator
              respond "Collaborator <@#{user.id}> removed.", dest
              @repl_sessions[@repl_sessions[from][:user_creator]][:collaborators].delete(from)
              @repl_sessions.delete(from)
            else
              open("#{config.path}/repl/#{@channel_id}/#{@repl_sessions[from][:name]}.input", 'a+') {|f|
                f.puts code
              }
              respond "REPL session finished: #{@repl_sessions[from][:name]}", dest
              unreact :running, @ts_react[@repl_sessions[from].name]
              pids = `pgrep -P #{@repl_sessions[from][:pid]}`.split("\n").map(&:to_i) #todo: it needs to be adapted for Windows
              pids.each do |pid|
                begin
                  Process.kill("KILL", pid)
                rescue
                end
              end
              @repl_sessions[from][:collaborators].each do |collaborator|
                @repl_sessions.delete(collaborator)
              end
              @repl_sessions.delete(from)
            end
          when /\A\s*-/i
            #ommit
          else
            if @ts_repl[@repl_sessions[from].name].to_s == ''
              @ts_repl[@repl_sessions[from].name] = Thread.current[:ts]
              react :running 
            end
            open("#{config.path}/repl/#{@channel_id}/#{@repl_sessions[from][:name]}.input", 'a+') {|f|
              f.puts code
            }
          end
        end
      end
    end
  end
end
