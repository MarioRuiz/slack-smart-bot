
#path to the project folder
# for example "#{`eval echo ~$USER`.chop}/projects/the_project"
def project_folder()
  "#{config.path}"
end

#link to the project
def git_project()
  ""
end

config.jira = {host: "https://#{ENV['JIRA_HOST']}", user: 'smartbot', password: ENV['JIRA_PASSWORD']} if config.jira.host == ""

#for the case of testing, just run this file adding in the end a call to rules with the parameters you want
if defined?(respond)
  @testing = false
else
  @testing = true
  @questions = Hash.new()

  def respond(message, dest)
    puts message
  end

  #context: previous message
  #to: user that should answer
  def ask(question, context, to, dest)
    puts "Bot: #{question}"
    @questions[to] = context
  end
end

# user: user slack object
# command: command to run
# processed: in case the command has been already processed on Bot class, by default false
# dest: channel_id
# files: files attached
# rules_file: rules_file name
#
# About the Help:
#   Add as a comment starting by "help:" the help you need to add to the `bot help` and `bot rules` commands.
#   The command logic needs to be added with ``, and the parameters to supply need to be in capital for example: `echo SOMETHING`
#
# help: ===================================
# help:
# help: *These are specific commands for this bot on this Channel.*
# help:     They will be accessible only when the bot is listening to you just writing the command
# help:     or the bot is not listening to you but requested on demand, or in a private conversation with the Smart Bot.
# help:     To run a command on demand:
# help:       `!THE_COMMAND`
# help:       `@NAME_OF_BOT THE_COMMAND`
# help:       `NAME_OF_BOT THE_COMMAND`
# help:     To run a command on demand and add the respond on a thread:
# help:       `^THE_COMMAND`
# help:       `!!THE_COMMAND`
# help:
def rules(user, command, processed, dest, files = [], rules_file = "")
  from = "#{user.team_id}_#{user.name}"
  display_name = user.profile.display_name

  if @testing
    puts "#{from}: #{command}"
    if @questions.keys.include?(from)
      context = @questions[from]
      @questions[from] = command
      command = context
    end
  end

  load "#{config.path}/rules/general_rules.rb"

  if general_rules(user, command, processed, dest, files, rules_file)
    return true
  else
    begin
      case command

      when /^set_access$/
        config.allow_access = {
          bot_help: ['marioruizs', 'UMYQS8E7L'],
          bot_rules: ['marioruizs', 'UMYQS8E7L'],
          bot_status: ['marioruizs', 'UMYQS8E7L'],
          use_rules: ['marioruizs', 'UMYQS8E7L'],
          add_shortcut: ['marioruizs', 'UMYQS8E7L'],
          delete_shortcut: ['marioruizs', 'UMYQS8E7L'],
          repl: ['marioruizs', 'UMYQS8E7L'],
          ruby_code: ['marioruizs', 'UMYQS8E7L'],
          see_shortcuts: ['marioruizs', 'UMYQS8E7L'],
          create_bot: ['marioruizs', 'UMYQS8E7L']
        }
      when /^unset_access$/
        config.allow_access = {
        }

      # help: ----------------------------------------------
      # help: `which rules`
      # help:  which rules for bot1cm
      # help:
      when /^which\s+rules$/i
        save_stats :which_rules
        respond "bot1cm"
        react :thumbsup

      when /^test silent (.+)$/i
        tempo = $1
        if Time.now.to_s > tempo
          respond "Now yes"
        end
      when /^respond on thread/i
        respond 'on_thread', :on_thread

      when /^respond direct/i
        respond 'direct', :direct

        # help: ----------------------------------------------
        # help: Example of help with many lines
        # help:   .
        # help:   .
        # help:   .
        # help:   .
        # help:   .
        # help:   .
        # help:   .
        # help:   .
        # help:   .
        # help:   .
        # help:   .
        # help:   .
        # help:   .
        # help:   .
        # help:   .
        # help:   .
        # help:   .
        # help:   .
        # help:   .
        # help:


        # help: ----------------------------------------------
        # help: `go to sleep`
        # help:   it will sleep the bot for 5 seconds
        # help:   that's all
        # help: command_id: :go_to_sleep
        # help:
      when /^go\sto\ssleep/i
        if answer.empty?
          ask "do you want me to take a siesta?"
        else
          case answer
          when /yes/i, /yep/i, /sure/i
            answer_delete
            respond "I'll be sleeping for 5 secs... just for you"
            respond "zZzzzzzZZZZZZzzzzzzz!"
            sleep 5
          when /no/i, /nope/i, /cancel/i
            answer_delete
            respond "Thanks, I'm happy to be awake"
          else
            respond "I don't understand"
            ask "are you sure you want me to sleep? (yes or no)"
          end
        end

        # helpadmin: ----------------------------------------------
        # helpadmin: `run something`
        # helpadmin:   It will run the process and report the results when done
        # helpadmin:
      when /^run something/i
        if has_access?(:run_something, user)
          respond "Running"

          process_to_run = "ruby -v"
          process_to_run = ("cd #{project_folder} &&" + process_to_run) if defined?(project_folder)
          stdout, stderr, status = Open3.capture3(process_to_run)
          if stderr == ""
            if stdout == ""
              respond "#{display_name}: Nothing returned."
            else
              respond "#{display_name}: #{stdout}"
            end
          else
            respond "#{display_name}: #{stderr}"
          end
        end

        # Example downloading a file from slack
        #  if !files.nil? and files.size == 1 and files[0].filetype == 'yaml'
        #    require 'nice_http'
        #    http = NiceHttp.new(host: "https://files.slack.com", headers: { "Authorization" => "Bearer #{config[:token]}" })
        #    http.get(files[0].url_private_download, save_data: './tmp/')
        #  end

        # Examples sending a file to slack:
        #   send_file(to, msg, filepath, title, format, type = "text")
        #   send_file(dest, 'the message', "#{project_folder}/temp/logs_ptBI.log", 'title', 'text/plain', "text")
        #   send_file(dest, 'the message', "#{project_folder}/temp/example.jpeg", 'title', 'image/jpeg', "jpg")

      else
        unless processed
          dont_understand()
        end
        return false
      end
      return true
    rescue => exception
      if defined?(@logger)
        @logger.fatal exception
        respond "Unexpected error!! Please contact an admin to solve it: <@#{config.admins.join(">, <@")}>"
      else
        puts exception
      end
      return false
    end
  end
end

#for the case of testing just running this file, write the dialogue in here:
if @testing
  require "nice_hash"
  user = { name: "Peter Johnson", id: "Uxxxxxx" }

  rules user, "go to sleep, you look tired", false, nil
  rules user, "yes", false, nil
end
