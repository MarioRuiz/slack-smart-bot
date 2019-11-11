
#path to the project folder
# for example "#{`eval echo ~$USER`.chop}/projects/the_project"
def project_folder()
  "#{`eval echo ~$USER`.chop}/"
end

#link to the project
def git_project()
  ""
end

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
# help:
def rules(user, command, processed, dest, files = [], rules_file = "")
  from = user.name
  display_name = user.profile.display_name

  if @testing
    puts "#{from}: #{command}"
    if @questions.keys.include?(from)
      context = @questions[from]
      @questions[from] = command
      command = context
    end
  end
  begin
    case command

    # help: ----------------------------------------------
    # help: `echo SOMETHING`
    # help:     repeats SOMETHING
    # help:
    when /^echo\s(.+)/i
      respond $1, dest

      # help: ----------------------------------------------
      # help: `go to sleep`
      # help:   it will sleep the bot for 5 seconds
      # help:
    when /^go\sto\ssleep/i
      unless @questions.keys.include?(from)
        ask("do you want me to take a siesta?", command, from, dest)
      else
        case @questions[from]
        when /yes/i, /yep/i, /sure/i
          @questions.delete(from)
          respond "I'll be sleeping for 5 secs... just for you", dest
          respond "zZzzzzzZZZZZZzzzzzzz!", dest
          sleep 5
        when /no/i, /nope/i, /cancel/i
          @questions.delete(from)
          respond "Thanks, I'm happy to be awake", dest
        else
          respond "I don't understand", dest
          ask("are you sure do you want me to sleep? (yes or no)", command, from, dest)
        end
      end

      # help: ----------------------------------------------
      # help: `run something`
      # help:   It will run the process and report the results when done
      # help:
    when /^run something/i
      respond "Running", dest

      process_to_run = "ruby -v"
      process_to_run = ("cd #{project_folder} &&" + process_to_run) if defined?(project_folder)
      stdout, stderr, status = Open3.capture3(process_to_run)
      if stderr == ""
        if stdout == ""
          respond "#{display_name}: Nothing returned.", dest
        else
          respond "#{display_name}: #{stdout}", dest
        end
      else
        respond "#{display_name}: #{stdout} #{stderr}", dest
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
        dont_understand(rules_file, command, user, dest)
      end
    end
  rescue => exception
    if defined?(@logger)
      @logger.fatal exception
      respond "Unexpected error!! Please contact an admin to solve it: <@#{ADMIN_USERS.join(">, <@")}>", dest
    else
      puts exception
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
