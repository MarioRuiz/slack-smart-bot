class SlackSmartBot
  def repl_client(from, session_name, type, serialt, env_vars)
    message = "Session name: *#{session_name}*
        From now on I will execute all you write as a Ruby command and I will keep the session open until you send `quit` or `bye` or `exit`. 
        In case you need someone to help you with the session you can add collaborators by sending `add collaborator @USER` to the session.
        I will respond with the result so it is not necessary you send `print`, `puts`, `p` or `pp` unless you want it as the output when calling `run repl`. 
        Use `p` to print a message raw, exacly like it is returned. 
        If you want to avoid a message to be treated by me, start the message with '-'. 
        After 30 minutes of no communication with the Smart Bot the session will be dismissed.
        If you want to see the methods of a class or module you created use _ls TheModuleOrClass_
        To see the code of a method: _code TheModuleOrClass.my_method_. To see the documentation of a method: _doc TheModuleOrClass.my_method_
        You can supply the Environmental Variables you need for the Session
        Example:
          _repl CreateCustomer LOCATION=spain HOST='https://10.30.40.50:8887'_
        "
    respond message

    File.write("#{config.path}/repl/#{@channel_id}/#{@repl_sessions[from][:name]}.input", "", mode: "a+")
    File.write("#{config.path}/repl/#{@channel_id}/#{@repl_sessions[from][:name]}.output", "", mode: "a+")
    File.write("#{config.path}/repl/#{@channel_id}/#{@repl_sessions[from][:name]}.run", "", mode: "a+")

    if type != :private_clean and type != :public_clean
      pre_execute = '
            if File.exist?(\"./.smart-bot-repl\")
              begin
                eval(File.read(\"./.smart-bot-repl\"), bindme' + serialt + ")
              rescue Exception => resp_repl
              end
            end
          "
    else
      pre_execute = ""
    end

    process_to_run = "
            " + env_vars.join("\n") + '
            require \"amazing_print\"
            require \"stringio\"
            require \"method_source\"
            bindme' + serialt + ' = binding
            eval(\"require \'nice_http\'\" , bindme' + serialt + ')
            def get_met_params(obj, m=nil)
              result = ""
              if m.nil?
                met = obj
              else
                met = obj.method(m) 
              end
              met.source.split("\n").each { |line|
                line.gsub!("def", "")
                line.gsub!("self.", "")
                line.strip!
                line.gsub!(/\A(\w+)\(/, \'*`\1`* (\')
                line.gsub!(/\A(\w+)$/, \'*`\1`*\')
                if line.strip[-1] == ")" or (result.empty? and !line.include?("("))
                  line.gsub!(/\A(\w+)\s/, \'*`\1`* \') if !line.include?("(")
                  result << "#{line}"
                  result << " ..." if !line.include?("(") and !line.include?(")")
                  result << "\n"
                  break 
                else
                  result << "#{line}\n"
                end
              }
              result
            end
            def ls(obj)
              result = ""
              (obj.methods - Object.methods).sort.each do |m|
                result << get_met_params(obj, m)
                result << "\n"
              end
              puts result
            end
            def get_object(obj_txt)
              met = obj_txt.scan(/\.(\w+)/).flatten.last
            
              if met.nil? and obj_txt[0].match(/[A-Z]/) 
                obj = Object
                obj_txt.split("::").each do |cl|
                  if obj.const_defined?(cl.to_sym)
                    obj = obj.const_get(cl)
                  else
                    obj = nil
                    break
                  end
                end
              elsif met.nil? and obj_txt[0].match(/[a-z]/)
                begin
                  obj = self.method(obj_txt)
                rescue
                  obj = nil
                end     
              else
                cl = obj_txt.scan(/([\w\:]+)\./).flatten.first
                obj = Object
                cl.split("::").each do |cl|
                  if obj.const_defined?(cl.to_sym)
                    obj = obj.const_get(cl)
                  else
                    obj = nil
                    break
                  end
                end
                unless obj.nil?
                  if obj.respond_to?(met)
                    obj = obj.method(met)
                  elsif obj.instance_method(met)
                    obj = obj.instance_method(met)        
                  else
                    obj = nil
                  end
                end
            
              end    
            end
            
            def doc(obj_txt)
              obj = get_object(obj_txt)
              if !obj.nil? and obj.respond_to?(:source_location) and obj.respond_to?(:comment) and
                !obj.source_location.nil? and !obj.comment.nil?
                result = "_*#{obj.source_location.join(":").gsub(Dir.pwd,"").gsub(Dir.home,"")}*_\n\n"
                comment = obj.comment.gsub(/^\s*\#/, "")
                comment.gsub!(/^\s*#+\s*(\R|$)/, "")
                comment.gsub!(/^\s(\w)([\w\s\-]*):/i, \'*\1\2*:\')
                comment.gsub!(/^(\s+)(\w[\w\s\-]*):/i, \'\1*`\2`*:\')
                result << "#{comment}"
                result << "\n\n"
                result << get_met_params(obj)
              else
                result = "No documentation found for #{obj_txt}. The object doesn\'t exist or it is not accessible."
              end
              puts result
            end
            
            def source(obj_txt)
              obj = get_object(obj_txt)
              if !obj.nil? and obj.respond_to?(:source_location) and obj.respond_to?(:comment) and
                !obj.source_location.nil? and !obj.comment.nil?
                result = "# #{obj.source_location.join(":").gsub(Dir.pwd,"").gsub(Dir.home,"")}\n\n"
                result << "#{obj.source}"
              else
                result = "No source code found for #{obj_txt}. The object doesn\'t exist or it is not accessible."
              end
              puts result
            end
                        
            def code(obj_txt)
              source(obj_txt)
            end            

            file_run_path = \"' + +File.expand_path(config.path) + "/repl/" + @channel_id + "/" + session_name + '.rb\"
            file_input_repl = File.open(\"' + File.expand_path(config.path) + "/repl/" + @channel_id + "/" + session_name + '.input\", \"r\")
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
                  error = false
                  as_it_is = false
                  begin
                      if code_to_run_repl.match?(/^\s*ls\s+(.+)/)
                        add_to_run_repl = false
                        as_it_is = true
                      elsif code_to_run_repl.match(/^\s*doc\s+(.+)/)
                        add_to_run_repl = false
                        code_to_run_repl = \"doc \\\"#{$1}\\\"\"
                        as_it_is = true
                      elsif code_to_run_repl.match(/^\s*(code|source|src)\s+(.+)/)
                        add_to_run_repl = false
                        code_to_run_repl = \"source \\\"#{$2}\\\"\"
                      end
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
                    open(\"' + File.expand_path(config.path) + "/repl/" + @channel_id + "/" + session_name + '.output\", \"a+\") {|f|
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
                      open(\"' + File.expand_path(config.path) + "/repl/" + @channel_id + "/" + session_name + '.output\", \"a+\") {|f|
                        f.puts \"\`\`\`\n#{resp_repl}\`\`\`\"
                      }
                    else
                      if stdout_repl.to_s == \'\'
                        resp_repl = resp_repl.ai
                      else
                        resp_repl = stdout_repl 
                      end
                      open(\"' + File.expand_path(config.path) + "/repl/" + @channel_id + "/" + session_name + '.output\", \"a+\") {|f|
                        if as_it_is
                          f.puts resp_repl
                        else
                          f.puts \"\`\`\`\n#{resp_repl}\`\`\`\"
                        end
                      }
                    end
                    unless !add_to_run_repl
                      open(\"' + File.expand_path(config.path) + "/repl/" + @channel_id + "/" + session_name + '.run\", \"a+\") {|f|
                        f.puts code_to_run_repl
                      }
                    end
                  end
                end
              end
            end
        '
    process_to_run.gsub!('\"', '"')
    return process_to_run
  end
end
