class SlackSmartBot
  # help: ----------------------------------------------
  # help: `run repl SESSION_NAME`
  # help: `run repl SESSION_NAME ENV_VAR=VALUE ENV_VAR=VALUE`
  # help: `run repl SESSION_NAME PARAMS`
  # help: `run live SESSION_NAME`
  # help: `run irb SESSION_NAME`
  # help:     Will run the repl session specified and return the output.
  # help:     You can supply the Environmental Variables you need for the Session
  # help:     PARAMS: Also it is possible to supply code that will be run before the repl code on the same session.
  # help:     It will return only the values that were print out on the repl with puts, print, p or pp
  # help:     Example:
  # help:       _run repl CreateCustomer LOCATION=spain HOST='https://10.30.40.50:8887'_
  # help:     <https://github.com/MarioRuiz/slack-smart-bot#repl|more info>
  # help: command_id: :run_repl
  # help:
  def run_repl(dest, user, session_name, env_vars, prerun, rules_file)
    #todo: add tests
    from = user.name
    if has_access?(__method__, user)
      save_stats(__method__)
      Dir.mkdir("#{config.path}/repl") unless Dir.exist?("#{config.path}/repl")
      Dir.mkdir("#{config.path}/repl/#{@channel_id}") unless Dir.exist?("#{config.path}/repl/#{@channel_id}")
      code = prerun.join("\n")
      if File.exist?("#{config.path}/repl/#{@channel_id}/#{session_name}.run")
        if @repls.key?(session_name) and (@repls[session_name][:type] == :private or @repls[session_name][:type] == :private_clean) and
           (@repls[session_name][:creator_name] != user.name or @repls[session_name][:creator_team_id] != user.team_id) and
           !is_admin?(user)
          respond "The REPL with session name: #{session_name} is private", dest
        elsif !prerun.empty? and (code.match?(/System/i) or code.match?(/Kernel/i) or code.include?("File.") or
                                  code.include?("`") or code.include?("exec") or code.include?("spawn") or code.include?("IO.") or
                                  code.match?(/open3/i) or code.match?(/bundle/i) or code.match?(/gemfile/i) or code.include?("%x") or
                                  code.include?("ENV") or code.match?(/=\s*IO/) or code.include?("Dir.") or
                                  code.match?(/=\s*File/) or code.match?(/=\s*Dir/) or code.match?(/<\s*File/) or code.match?(/<\s*Dir/) or
                                  code.match?(/\w+:\s*File/) or code.match?(/\w+:\s*Dir/) or
                                  code.match?(/=?\s*(require|load)(\(|\s)/i))
          respond "Sorry I cannot run this due security reasons", dest
        else
          if @repls.key?(session_name) #not temp
            @repls[session_name][:accessed] = Time.now.to_s
            if @repls[session_name].creator_name == user.name and @repls[session_name].creator_team_id == user.team_id
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
              eval(File.new(config.path + rules_file).read) if File.exist?(config.path + rules_file)
            end
          end
          if File.exist?("#{project_folder}/.smart-bot-repl") and
             ((@repls.key?(session_name) and @repls[session_name][:type] != :private_clean and @repls[session_name][:type] != :public_clean) or !@repls.key?(session_name))
            content += File.read("#{project_folder}/.smart-bot-repl")
            content += "\n"
          end
          unless prerun.empty?
            content += prerun.join("\n")
            content += "\n"
          end
          content += File.read("#{config.path}/repl/#{@channel_id}/#{session_name}.run").gsub(/^(quit|exit|bye)$/i, "") #todo: remove this gsub, it will never contain it
          Dir.mkdir("#{project_folder}/tmp") unless Dir.exist?("#{project_folder}/tmp")
          Dir.mkdir("#{project_folder}/tmp/repl") unless Dir.exist?("#{project_folder}/tmp/repl")
          if Thread.current[:on_thread]
            # to force stdout.each to be performed every 3 seconds
            content = "Thread.new do
              while true do
                puts ''
                sleep 3
              end
            end
            #{content}
            "
          end
          random = "5:LN&".gen
          File.write("#{project_folder}/tmp/repl/#{session_name}_#{user.name}_#{random}.rb", content, mode: "w+")
          process_to_run = "ruby  ./tmp/repl/#{session_name}_#{user.name}_#{random}.rb"
          process_to_run = ("cd #{project_folder} && #{process_to_run}") if defined?(project_folder)
          respond "Running REPL #{session_name} (id: #{random})"
          @run_repls[random] = { team_id: user.team_id, user: user.name, name: session_name, pid: '' }
          react :running

          require "pty"
          timeout = 60 * 60 * 4 # 4 hours

          started = Time.now
          results = []
          begin
            PTY.spawn(process_to_run) do |stdout, stdin, pid|
              last_result = -1
              last_time = Time.now
              @run_repls[random].pid = pid
              begin
                stdout.each do |line|
                  if (Time.now - started) > timeout
                    respond "run REPL session finished. Max time reached: #{session_name} (id: #{random})", dest
                    pids = `pgrep -P #{pid}`.split("\n").map(&:to_i) #todo: it needs to be adapted for Windows
                    pids.each do |pd|
                      begin
                        Process.kill("KILL", pd)
                      rescue
                      end
                    end
                    break
                  else
                    results << line
                    if Thread.current[:on_thread]
                      if (Time.now - last_time) > 2
                        if (results.size - last_result) < 60 and results[(last_result + 1)..-1].join.size < 3500
                          output = ""
                          results[(last_result + 1)..-1].each do |li|
                            if li.match?(/^\s*{.+}\s*$/) or li.match?(/^\s*\[.+\]\s*$/)
                              output += "```\n#{li}```\n"
                            else
                              output += li
                            end
                          end
                          respond output
                        else
                          send_file(dest, "", "response.rb", "", "text/plain", "ruby", content: results[(last_result + 1)..-1].join)
                        end
                        last_result = results.size - 1
                        last_time = Time.now
                      end
                    end
                  end
                end
              rescue Errno::EIO
                @logger.warn "run_repl PTY Errno:EIO error"
              end
              if results.empty?
                respond "*#{session_name}* (id: #{random}): Nothing returned."
              else
                if last_result != (results.size - 1)
                  if (results.size - last_result) < 60 and results[(last_result + 1)..-1].join.size < 3500
                    output = ""
                    results[(last_result + 1)..-1].each do |li|
                      if li.match?(/^\s*{.+}\s*$/) or li.match?(/^\s*\[.+\]\s*$/)
                        output += "```\n#{li}```\n"
                      else
                        output += li
                      end
                    end
                    if Thread.current[:on_thread]
                      respond output
                    else
                      respond "*#{session_name}* (id: #{random}):\n#{output}"
                    end
                  else
                    send_file(dest, "", "response.rb", "", "text/plain", "ruby", content: results[(last_result + 1)..-1].join)
                  end
                end
              end
            end
          rescue PTY::ChildExited
            @logger.warn "run_repl PTY The child process exited!"
          end
          @run_repls.delete(random) if @run_repls.key?(random)
          unreact :running
        end
      else
        respond "The REPL with session name: #{session_name} doesn't exist on this Smart Bot Channel", dest
      end
    end
  end
end
