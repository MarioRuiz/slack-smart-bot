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
      when /\A(\d*)\s*(clear|cls|clear\s+screen)\s*/i
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


      else
        return false
      end
      return true
    rescue => exception
      if defined?(@logger)
        @logger.fatal exception
        respond "Unexpected error!! Please contact an admin to solve it: <@#{ADMIN_USERS.join(">, <@")}>"
      else
        puts exception
      end
      return false
    end
end