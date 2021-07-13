# add here the general commands you will be using in any channel where The SmartBot is part of. Not necessary to use ! or ^, it will answer directly.
def general_bot_commands(user, command, dest, files = [])
    
  begin
    if config.simulate
      display_name = user.profile.display_name
    else
      if user.profile.display_name.to_s.match?(/\A\s*\z/)
        user.profile.display_name = user.profile.real_name
      end
      display_name = user.profile.display_name
    end

    case command

      # help: ----------------------------------------------
      # help: `Hi Bot`
      # help: `Hi Smart`
      # help: `Hello Bot` `Hola Bot` `Hallo Bot` `What's up Bot` `Hey Bot` `Hæ Bot`
      # help: `Hello THE_NAME_OF_THE_BOT`
      # help:    Bot starts listening to you if you are on a Bot channel
      # help:    After that if you want to avoid a single message to be treated by the smart bot, start the message by -
      # help:    Also apart of Hello you can use _Hallo, Hi, Hola, What's up, Hey, Hæ_
      # help:    <https://github.com/MarioRuiz/slack-smart-bot#how-to-access-the-smart-bot|more info>
      # help:
      when /\A\s*(Hello|Hallo|Hi|Hola|What's\sup|Hey|Hæ)\s+(#{@salutations.join("|")})\s*$/i
          hi_bot(user, dest, user.name, display_name)

      # help: ----------------------------------------------
      # help: `Bye Bot`
      # help: `Bye Smart`
      # help: `Bye NAME_OF_THE_BOT`
      # help:    Bot stops listening to you if you are on a Bot channel
      # help:    Also apart of Bye you can use _Bæ, Good Bye, Adiós, Ciao, Bless, Bless Bless, Adeu_
      # help:    <https://github.com/MarioRuiz/slack-smart-bot#how-to-access-the-smart-bot|more info>
      # help:
      when /\A\s*(Bye|Bæ|Good\s+Bye|Adiós|Ciao|Bless|Bless\sBless|Adeu)\s+(#{@salutations.join("|")})\s*$/i
          bye_bot(dest, user.name, display_name)

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

        # help: ----------------------------------------------
        # help: `see statuses`
        # help: `see statuses #CHANNEL`
        # help: `see status EMOJI`
        # help: `see status EMOJI #CHANNEL`
        # help: `see status EMOJI1 EMOJI99`
        # help: `who is on vacation?`
        # help: `who is on EMOJI`
        # help: `who is on EMOJI #CHANNEL`
        # help: `who is on EMOJI1 EMOJI99`
        # help: `who is not on vacation?`
        # help: `who is not on EMOJI`
        # help:     It will display the current statuses of the members of the channel where you are calling the command or on the channel you supply.
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#see-statuses|more info>
        # help: 
      when /\A\s*(see|get)\s+(statuses)()\s*\z/i,
        /\A\s*(see\s+status|get\s+status|who\s+is\s+on|who\s+is\s+not\s+on)\s+(:[\w\-\:\s]+:)\s*\??()\s*\z/i,
        /\A\s*(who\s+is\s+on|who\s+is\s+not\s+on)\s+(vacation|holiday)\s*\??()\s*\z/i,
        /\A\s*(see|get)\s+(statuses)\s+#([\w\-]+)\s*\z/i,
        /\A\s*(see\s+status|get\s+status|who\s+is\s+on|who\s+is\s+not\s+on)\s+(:[\w\-\:\s]+:)\s*\??\s+#([\w\-]+)\s*\z/i,
        /\A\s*(who\s+is\s+on|who\s+is\s+not\s+on)\s+(vacation|holiday)\s*\??\s+#([\w\-]+)\s*\z/i,
        /\A\s*(see|get)\s+(statuses)\s+<#(C\w+)\|.+>\s*\z/i,
        /\A\s*(see\s+status|get\s+status|who\s+is\s+on|who\s+is\s+not\s+on)\s+(:[\w\-\:\s]+:)\s*\??\s+<#(C\w+)\|.+>\s*\z/i,
        /\A\s*(who\s+is\s+on|who\s+is\s+not\s+on)\s+(vacation|holiday)\s*\??\s+<#(C\w+)\|.+>\s*\z/i

        not_on = $1.match?(/who\s+is\s+not\s+on/i)
        type = $2.downcase
        channel = $3.to_s
        if type == 'statuses'
          types = []
        elsif type =='vacation' or type == 'holiday'
          types = [':palm_tree:']
        else
          type.gsub!(' ', '')
          type.gsub!('::',': :')
          types = type.split(' ')
        end
        see_statuses(user, channel, types, dest, not_on)


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