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
    when /\A\s*(\d*)\s*(clear|cls|clear\s+screen)\s*\z/i
      save_stats :cls
      $1.to_s == '' ? lines = 100 : lines = $1.to_i
      lines = 200 if lines > 200
      respond (">#{"\n"*lines}<")


      # this is a hidden command that it is not listed when calling bot help
    when /\A\s*(that's\s+)?(thanks|thank\s+you|I\s+love\s+you|nice|cool)\s+(#{@salutations.join("|")})\s*!*\s*$/i
      save_stats :thanks
      reactions = [:heart, :heart_eyes, :blush, :relaxed, :simple_smile, :smiley, :two_hearts, :heartbeat, :green_heart ]
      reactions.sample(rand(3)+1).each {|rt| react rt }
      responses = ['Thank YOU', "You're welcome", "You're very welcome", 'No problem', 'No worries', "Don't mention it", 'My pleasure', 
        'Anytime', 'It was the least I could do', 'Glad to help', 'Sure', 'Pleasure', 'The pleasure is mine', 'It was nothing', 'Much obliged', "I'm happy to help",
        'Það var ekkert', 'De nada', 'No hay de qué', 'De rien',  'Bitte', 'Prego', 'मेरा सौभाग्य है', '不客氣', 'Παρακαλώ']
      respond "#{responses.sample}#{'!'*rand(4)}"

        # help: ----------------------------------------------
        # help: `add announcement MESSAGE`
        # help: `add red announcement MESSAGE`
        # help: `add green announcement MESSAGE`
        # help: `add yellow announcement MESSAGE`
        # help: `add white announcement MESSAGE`
        # help: `add EMOJI announcement MESSAGE`
        # help:     It will store the message on the announcement list labeled with the color or emoji specified, white by default.
        # help:        aliases for announcement: statement, declaration, message
        # help:  Examples:
        # help:     _add green announcement :heavy_check_mark: All customer services are up and running_
        # help:     _add red declaration Customers db is down :x:_
        # help:     _add yellow statement Don't access the linux server without VPN_
        # help:     _add message Party will start at 20:00 :tada:_
        # help:     _add :heavy_exclamation_mark: message Pay attention all DB are on maintenance until 20:00 GMT_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#announcements|more info>
        # help: 
      when /\A\s*(add|create)\s+(red\s+|green\s+|white\s+|yellow\s+)?(announcement|statement|declaration|message)\s+(.+)\s*\z/i,
        /\A\s*(add|create)\s+(:\w+:)\s+(announcement|statement|declaration|message)\s+(.+)\s*\z/i
        type = $2.to_s.downcase.strip
        type = 'white' if type == ''
        message = $4
        add_announcement(user, type, message)
        

        # help: ----------------------------------------------
        # help: `delete announcement ID`
        # help:     It will delete the message on the announcement list.
        # help:        aliases for announcement: statement, declaration, message
        # help:  Examples:
        # help:     _delete announcement 24_
        # help:     _delete message 645_
        # help:     _delete statement 77_
        # help:     _delete declaration 334_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#announcements|more info>
        # help: 
      when /\A\s*(delete|remove)\s+(announcement\s+|statement\s+|declaration\s+|message\s+)?(\d+)\s*\z/i
        message_id = $3
        delete_announcement(user, message_id)

        # help: ----------------------------------------------
        # help: `see announcements`
        # help: `see red announcements`
        # help: `see green announcements`
        # help: `see yellow announcements`
        # help: `see white announcements`
        # help: `see EMOJI announcements`
        # helpmaster: `see announcements #CHANNEL`
        # helpmaster: `see all announcements`
        # help:     It will display the announcements for the channel.
        # help:        aliases for announcements: statements, declarations, messages
        # helpmaster:        In case #CHANNEL it will display the announcements for that channel. Only master admins can use it from a DM with the Smartbot.
        # helpmaster:        In case 'all' it will display all the announcements for all channels. Only master admins can use it from a DM with the Smartbot.
        # help:  Examples:
        # help:     _see announcements_
        # help:     _see white messages_
        # help:     _see red statements_
        # help:     _see yellow declarations_
        # help:     _see messages_
        # help:     _see :heavy_exclamation_mark: messages_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#announcements|more info>
        # help: 
      when /\A\s*see\s+(red\s+|green\s+|white\s+|yellow\s+|:\w+:\s+)?(announcements|statements|declarations|messages)()\s*\z/i,
        /\A\s*see\s+(all\s+)?(announcements|statements|declarations|messages)()\s*\z/i,
        /\A\s*see\s+(red\s+|green\s+|white\s+|yellow\s+|:\w+:\s+)?(announcements|statements|declarations|messages)\s+#([\w\-]+)\s*\z/i,
        /\A\s*see\s+(red\s+|green\s+|white\s+|yellow\s+|:\w+:\s+)?(announcements|statements|declarations|messages)\s+<#(C\w+)\|.+>\s*\z/i

        type = $1.to_s.downcase.strip
        channel = $3.to_s

        see_announcements(user, type, channel)

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