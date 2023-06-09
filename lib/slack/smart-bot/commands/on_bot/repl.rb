class SlackSmartBot
  # help: ----------------------------------------------
  # help: >*<https://github.com/MarioRuiz/slack-smart-bot#repl|REPLs>*
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
  # help:     To see the code of a method: _code TheModuleOrClass.my_method_
  # help:     To see the documentation of a method: _doc TheModuleOrClass.my_method_
  # help:     You can ask *ChatGPT* to help you or suggest any code by sending the message: `? PROMPT`
  # help:     If you send just `?` it will suggest some code to be added.
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
        if session_name.to_s == ""
          session_name = "#{from}_#{serialt}"
          temp_repl = true
        else
          temp_repl = false
          i = 0
          name = session_name
          while File.exist?("#{config.path}/repl/#{@channel_id}/#{session_name}.input")
            i += 1
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
          user_creator: from,
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
            gets: 0,
          }
          update_repls()
        end
        react :running
        @ts_react ||= {}
        if Thread.current[:ts].to_s == ""
          @ts_react[session_name] = Thread.current[:thread_ts]
        else
          @ts_react[session_name] = Thread.current[:ts]
        end
        @ts_repl ||= {}
        @ts_repl[session_name] = ""
        process_to_run = repl_client(from, session_name, type, serialt, env_vars)

        unless rules_file.empty? # to get the project_folder
          begin
            eval(File.new(config.path + rules_file).read) if File.exist?(config.path + rules_file)
          end
        end

        file_run_path = "./tmp/repl/#{@channel_id}/#{session_name}.rb"
        if defined?(project_folder)
          Dir.mkdir("#{project_folder}/tmp/") unless Dir.exist?("#{project_folder}/tmp/")
          Dir.mkdir("#{project_folder}/tmp/repl") unless Dir.exist?("#{project_folder}/tmp/repl")
          Dir.mkdir("#{project_folder}/tmp/repl/#{@channel_id}/") unless Dir.exist?("#{project_folder}/tmp/repl/#{@channel_id}/")
          file_run = File.open(file_run_path.gsub("./", "#{project_folder}/"), "w")
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
        timeout = TIMEOUT_LISTENING # 30 minutes

        file_output_repl = File.open("#{config.path}/repl/#{@channel_id}/#{session_name}.output", "r")
        @repl_sessions[from][:pid] = wait_thr.pid
        @repl_sessions[from][:output] ||= []
        @repl_sessions[from][:input_output] ||= []
        @repl_sessions[from][:input_output] << "Please chatgpt return code in Ruby language."
        if File.exist?("#{project_folder}/.smart-bot-repl") and type != :private_clean and type != :public_clean
            pre_input = File.read("#{project_folder}/.smart-bot-repl")
            @repl_sessions[from][:input_output] << "```\n#{pre_input}\n```"
            respond "*Preloaded source code:*\n```\n#{pre_input}\n```"
        end

        while (wait_thr.status == "run" or wait_thr.status == "sleep") and @repl_sessions.key?(from)
          begin
            if (Time.now - @repl_sessions[from][:finished]) > timeout
              open("#{config.path}/repl/#{@channel_id}/#{@repl_sessions[from][:name]}.input", "a+") { |f|
                f.puts "quit"
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
            if resp_repl.to_s != ""
              if @ts_repl[@repl_sessions[from].name].to_s != ""
                unreact(:running, @ts_repl[@repl_sessions[from].name])
                @ts_repl[@repl_sessions[from].name] = ""
              end
              if (resp_repl.to_s.lines.count < 60 and resp_repl.to_s.size < 3500) or
                 resp_repl.match?(/^\s*[_\*]*`\w+`/im)
                respond resp_repl, dest
              else
                resp_repl.gsub!(/^\s*```/, "")
                resp_repl.gsub!(/```\s*$/, "")
                send_file(dest, "", "response.rb", "", "text/plain", "ruby", content: resp_repl)
              end
              @repl_sessions[from][:output] << resp_repl
              @repl_sessions[from][:input_output] << resp_repl
            end
          rescue Exception => excp
            @logger.fatal excp
          end
        end
      elsif @repl_sessions.key?(from) and @repl_sessions[from][:command].to_s == ""
        respond "You are already in a repl on this SmartBot. You need to quit that one before starting a new one."
      else
        @repl_sessions[from][:finished] = Time.now
        code = @repl_sessions[from][:command]
        @repl_sessions[from][:command] = ""
        code.gsub!("\\n", "\n")
        code.gsub!("\\r", "\r")
        # Disabled for the moment since it is deleting lines with '}'
        #code.gsub!(/^\W*$/, "") #to remove special chars from slack when copy/pasting.
        if code.match?(/\A\s*-/i)          
          # don't treat
        elsif code.match(/\A\s*\?\s*(.*)\s*\z/im)
          save_stats :open_ai_chat
          #call chatgpt when: ? prompt
          #if no prompt then suggest next code line
          prompt = $1
          prompt = "suggest next code line" if prompt.to_s == ""
          @repl_sessions[user.name][:chat_gpt] ||= {}
          react :speech_balloon
          if !@repl_sessions[user.name][:chat_gpt].key?(:client) or @repl_sessions[user.name][:chat_gpt][:client].nil?
            get_personal_settings()
            tmp_repl_sessions, message_connect = SlackSmartBot::AI::OpenAI.connect(@repl_sessions, config, @personal_settings, reconnect: true, service: :chat_gpt)
            @repl_sessions[user.name][:chat_gpt] = tmp_repl_sessions[user.name][:chat_gpt]
            respond message_connect if message_connect
          end
          @repl_sessions[user.name][:chat_gpt][:prompts] ||= []
          unless @repl_sessions[user.name][:chat_gpt][:client].nil?
            model ||= @repl_sessions[user.name][:chat_gpt][:smartbot_model]
            #todo: add source code to the prompt
            @repl_sessions[user.name][:chat_gpt][:prompts] << prompt
            @repl_sessions[from][:input_output] << prompt
            prompts = @repl_sessions[user.name][:input_output].join("\n")
            success, res = SlackSmartBot::AI::OpenAI.send_gpt_chat(@repl_sessions[user.name][:chat_gpt][:client], model, prompts, @repl_sessions[user.name].chat_gpt)
            if success
              @repl_sessions[user.name][:chat_gpt][:prompts] << res
              respond "*ChatGPT>* _#{model}_\n#{res}"
              @repl_sessions[from][:input_output] << res
            elsif res.to_s.strip!=''
              respond "*ChatGPT>* _#{model}_\n#{res}"
            else
              respond "ChatGPT: Sorry, I cannot chat right now. Please try again later."
            end
          end
          unreact :speech_balloon
        elsif code.match?(/System/i) or code.match?(/Kernel/i) or code.include?("File.") or
              code.include?("`") or code.include?("exec") or code.include?("spawn") or code.include?("IO.") or
              code.match?(/open3/i) or code.match?(/bundle/i) or code.match?(/gemfile/i) or code.include?("%x") or
              code.include?("ENV") or code.match?(/=\s*IO/) or code.include?("Dir.") or
              code.match?(/=\s*File/) or code.match?(/=\s*Dir/) or code.match?(/<\s*File/) or code.match?(/<\s*Dir/) or
              code.match?(/\w+:\s*File/) or code.match?(/\w+:\s*Dir/) or
              code.match?(/=?\s*(require|load)(\(|\s)/i)
          respond "Sorry I cannot run this due security reasons", dest
        elsif code.match(/\A\s*add\s+collaborator\s+<@(\w+)>\s*\z/i)
          collaborator = $1
          user_info = @users.select { |u| u.id == collaborator or (u.key?(:enterprise_user) and u.enterprise_user.id == collaborator) }[-1]
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
              user_creator: creator,
            }
          end
        else
          if @repl_sessions[from][:user_type] == :collaborator
            creator = @repl_sessions[from][:user_creator]
            @repl_sessions[@repl_sessions[from][:user_creator]][:input] << code
          else
            creator = from
            @repl_sessions[from][:input] << code
          end
          if code.include?("```")
            @repl_sessions[creator][:input_output] << code
          else
            @repl_sessions[creator][:input_output] << "```\n#{code}\n```"
          end
          case code
          when /^\s*(quit|exit|bye|bye\s+bot)\s*$/i
            if @repl_sessions[from][:user_type] == :collaborator
              respond "Collaborator <@#{user.id}> removed.", dest
              @repl_sessions[creator][:collaborators].delete(from)
              @repl_sessions.delete(from)
            else
              open("#{config.path}/repl/#{@channel_id}/#{@repl_sessions[from][:name]}.input", "a+") { |f|
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
          else
            if @ts_repl[@repl_sessions[creator].name].to_s == ""
              @ts_repl[@repl_sessions[creator].name] = Thread.current[:ts]
              react :running
            end
            open("#{config.path}/repl/#{@channel_id}/#{@repl_sessions[creator][:name]}.input", "a+") { |f|
              f.puts code
            }
          end
        end
      end
    end
  end
end
