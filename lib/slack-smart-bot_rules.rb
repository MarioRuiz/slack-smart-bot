
#path to the project folder
# for example "#{`eval echo ~$USER`.chop}/projects/the_project"
def project_folder()
  "#{Dir.pwd}/"
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
# help:     To run a command on demand and add the respond on a thread:
# help:       `^THE_COMMAND`
# help:       `!!THE_COMMAND`
# help:
def rules(user, command, processed, dest, files = [], rules_file = "")
  from = user.name
  display_name = user.profile.display_name

  load "#{config.path}/rules/general_rules.rb"
  
  if general_rules(user, command, processed, dest, files, rules_file)
    return true
  else
    begin
      case command

        # help: ----------------------------------------------
        # help: `go to sleep`
        # help:   it will sleep the bot for 5 seconds
        # help: command_id: :go_to_sleep
        # help:
      when /\A\s*go\sto\ssleep/i
        save_stats :go_to_sleep
        if answer.empty?
          ask "do you want me to take a siesta?"
        else
          case answer
          when /yes/i, /yep/i, /sure/i
            answer_delete
            respond "I'll be sleeping for 5 secs... just for you"
            respond "zZzzzzzZZZZZZzzzzzzz!"
            react :sleeping
            sleep 5
            unreact :sleeping
            react :sunny
          when /no/i, /nope/i, /cancel/i
            answer_delete
            respond "Thanks, I'm happy to be awake"
          else
            respond "I don't understand"
            ask "are you sure you want me to sleep? (yes or no)"
          end
        end

        # help: ----------------------------------------------
        # help: `run something`
        # help:   It will run the process and report the results when done
        # help: command_id: :run_something
        # help:
      when /\Arun something/i
        save_stats :run_something
        if has_access?(:run_something, user)
          react :runner

          process_to_run = "ruby -v"
          process_to_run = ("cd #{project_folder} &&" + process_to_run) if defined?(project_folder)
          stdout, stderr, status = Open3.capture3(process_to_run)
          unreact :runner
          if stderr == ""
            if stdout == ""
              respond "#{display_name}: Nothing returned."
            else
              respond "#{display_name}: #{stdout}"
            end
          else
            respond "#{display_name}: #{stdout} #{stderr}"
          end
        end
        
        # Emoticons you can use with `react` command https://www.webfx.com/tools/emoji-cheat-sheet/
        
        # Examples for respond, respond_thread and respond_direct
        #   # send 'the message' to the channel or direct message where the command was written
        #   respond "the message"
        #   # send 'the message' privately as a direct message to the user that sent the command
        #   respond_direct "the message"
        #   # same thing can be done:
        #   respond "the message", :direct
        #   # send 'the message' opening a thread
        #   respond_thread "the message"
        #   # same thing can be done:
        #   respond 'the message', :on_thread
        #   # send 'the message' to a specific channel name
        #   respond "the message", 'my_channel'
        #   # send 'the message' to a specific channel id
        #   respond "the message", 'CSU34D33'
        #   # send 'the message' to a specific user as direct message
        #   respond "the message", '@theuser'
        #   # send 'the message' to a specific user id as direct message
        #   respond "the message", 'US3344D3'

        # Example sending blocks https://api.slack.com/block-kit
        # my_blocks = [
        #   { type: "context",
        #     elements:
        #       [
        #         { type: "plain_text", :text=>"\tInfo: " },
        #         { type: "image", image_url: "https://avatars.slack-edge.com/2021-03-23/182815_e54abb1dd_24.jpg", alt_text: "mario" },
        #         { type: "mrkdwn", text: " *Mario Ruiz* (marior)  " }
        #       ]
        #   }
        # ]
        # respond blocks: my_blocks

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
      @logger.fatal exception
      respond "Unexpected error!! Please contact an admin to solve it: <@#{config.admins.join(">, <@")}>"
      return false
    end
  end
end
