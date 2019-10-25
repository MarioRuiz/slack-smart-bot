
#path to the project folder
# for example "#{`eval echo ~$USER`.chop}/projects/the_project"
def project_folder()
  "#{`eval echo ~$USER`.chop}/"
end

#link to the project
def git_project()
  ""
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

  begin
    case command

    # help: ----------------------------------------------
    # help: `echo SOMETHING`
    # help:     repeats SOMETHING
    # help:
    when /^echo\s(.+)/i
      respond $1

      # help: ----------------------------------------------
      # help: `go to sleep`
      # help:   it will sleep the bot for 5 seconds
      # help:
    when /^go\sto\ssleep/i
      unless @questions.keys.include?(from)
        ask "do you want me to take a siesta?"
      else
        case @questions[from]
        when /yes/i, /yep/i, /sure/i
          @questions.delete(from)
          respond "I'll be sleeping for 5 secs... just for you"
          respond "zZzzzzzZZZZZZzzzzzzz!"
          sleep 5
        when /no/i, /nope/i, /cancel/i
          @questions.delete(from)
          respond "Thanks, I'm happy to be awake"
        else
          respond "I don't understand"
          ask "are you sure do you want me to sleep? (yes or no)"
        end
      end

      # help: ----------------------------------------------
      # help: `run something`
      # help:   It will run the process and report the results when done
      # help:
    when /^run something/i
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
        respond "#{display_name}: #{stdout} #{stderr}"
      end

      # Examples for respond and respond_direct
      #   # send 'the message' to the channel or direct message where the command was written
      #   respond "the message"
      #   # send 'the message' privately as a direct message to the user that sent the command
      #   respond_direct "the message"
      #   # send 'the message' to a specific channel name
      #   respond "the message", 'my_channel'
      #   # send 'the message' to a specific channel id
      #   respond "the message", 'CSU34D33'
      #   # send 'the message' to a specific user as direct message
      #   respond "the message", '@theuser'
      #   # send 'the message' to a specific user id as direct message
      #   respond "the message", 'US3344D3'

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
        if @channel_id == dest or dest[0] == "D" or dest[0] == "G" #not on extended channels
          dont_understand()
        end
      end
    end
  rescue => exception
    @logger.fatal exception
    respond "Unexpected error!! Please contact an admin to solve it: <@#{config.admins.join(">, <@")}>"
  end
end
