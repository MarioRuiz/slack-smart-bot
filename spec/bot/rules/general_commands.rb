# add here the general commands you will be using in any channel where The SmartBot is part of. Not necessary to use ! or ^, it will answer directly.
def general_commands(user, command, dest, files = [])
    
  begin
    case command

      # help: ----------------------------------------------
      # help: `cls`
      # help: `clear`
      # help: `clear screen`
      # help: `NUMBER cls`
      # help:     It will send a big empty message.
      # help:        NUMBER (optional): number of lines. Default 100. Max 200.
      # help: 
    when /\A(\d*)\s*(clear|cls|clear\s+screen)\s*\z/i
      save_stats :cls
      $1.to_s == '' ? lines = 100 : lines = $1.to_i
      lines = 200 if lines > 200
      respond (">#{"\n"*lines}<")


      # this is a hidden command that it is not listed when calling bot help
    when /\A\s*(that's\s+)?(thanks|thank\s+you|I\s+love\s+you|nice|cool)\s+(#{@salutations.join("|")})\s*!*\s*/i
      save_stats :thanks
      reactions = [:heart, :heart_eyes, :blush, :relaxed, :simple_smile, :smiley, :two_hearts, :heartbeat, :green_heart ]
      reactions.sample(rand(3)+1).each {|rt| react rt }
      responses = ['Thank YOU', "You're welcome", "You're very welcome", 'No problem', 'No worries', "Don't mention it", 'My pleasure', 
        'Anytime', 'It was the least I could do', 'Glad to help', 'Sure', 'Pleasure', 'The pleasure is mine', 'It was nothing', 'Much obliged', "I'm happy to help",
        'Það var ekkert', 'De nada', 'No hay de qué', 'De rien',  'Bitte', 'Prego', 'मेरा सौभाग्य है', '不客氣', 'Παρακαλώ']
      respond "#{responses.sample}#{'!'*rand(4)}"

      # this is a hidden command that it is not listed when calling bot help
    when /\s*.*happy\s+birthday.*(<@\w+>)\s*.*$/i, /\s*.*(<@\w+>).*happy\s+birthday\s*.*$/i
      unless Thread.current[:on_thread]
        save_stats :happy_birthday
        happy_user = $1
        reactions = [:tada, :cake, :birthday]
        sleep 30
        reactions.sample(rand(3)+1).each {|rt| react rt }
        sleep (rand(10)+5)*60 # so SmartBot is not the first one
        responses = ['Happy birthday', "Very happy birthday", "Happy happy happy birthday", "Have a fabulous birthday", 'May all your wishes come true',
        'Many happy returns of the day', 'I wish you a wonderful birthday', 'Have a great one', 'I hope you have a fantastic day and a fantastic year to come',
        'To your happiness', "Don't count the candles. Enjoy the party", 'May your day be as awesome as you are', 'The best things in life are yet to come']
        respond "#{happy_user} #{responses.sample}#{'!'*rand(4)}", :on_thread
      end

    else
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