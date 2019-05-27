#for the case of testing, just run this file adding in the end a call to rules with the parameters you want
if defined?(respond)
  @testing = false
else
  @testing = true
  @questions = Hash.new()

  def respond(message, id_user)
    puts message
  end

  #context: previous message
  #to: user that should answer
  def ask(question, context, to, id_user)
    puts "Bot: #{question}"
    @questions[to] = context
  end
end

# from: Full name of the person sending the message
# command: command to run
# processed: in case the command has been already processed on Bot class, by default false
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
def rules(user, command, processed, id_user)
  from = user.name
  if @testing
    puts "#{from}: #{command}"
    if @questions.keys.include?(from)
      context = @questions[from]
      @questions[from] = command
      command = context
    end
  end
  firstname = from.split(" ").first
  case command

  # help: ----------------------------------------------
  # help: `echo SOMETHING`
  # help:     repeats SOMETHING
  # help:
  when /^echo\s(.+)/i
    respond $1, id_user

    # help: ----------------------------------------------
    # help: `go to sleep`
    # help:   it will sleep the bot for 5 seconds
    # help:
  when /^go\sto\ssleep/i
    unless @questions.keys.include?(from)
      ask("do you want me to take a siesta?", command, from, id_user)
    else
      case @questions[from]
      when /yes/i, /yep/i, /sure/i
        @questions.delete(from)
        respond "zZzzzzzZZZZZZzzzzzzz!", id_user
        respond "I'll be sleeping for 5 secs... just for you", id_user
        sleep 5
      when /no/i, /nope/i, /cancel/i
        @questions.delete(from)
        respond "Thanks, I'm happy to be awake", id_user
      else
        respond "I don't understand", id_user
        ask("are you sure do you want me to sleep? (yes or no)", "go to sleep", from, id_user)
      end
    end
  else
    unless processed
      resp = %w{ what huh sorry }.sample
      respond "#{firstname}: #{resp}?", id_user
    end
  end
end

#for the case of testing just running this file, write the dialogue in here:
if @testing
  require 'nice_hash'
  user = {name: "Peter Johson", id: "Uxxxxxx"}

  rules user, "go to sleep, you look tired", false, nil
  rules user, "yes", false, nil
end
