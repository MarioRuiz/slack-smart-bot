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
      # help: `bot help`
      # help: `bot help COMMAND`
      # help: `bot rules`
      # help: `bot rules COMMAND`
      # help: `bot help expanded`
      # help: `bot rules expanded`
      # help: `bot what can I do?`
      # help:    it will display this help. For a more detailed help call `bot help expanded` or `bot rules expanded`.
      # help:    if COMMAND supplied just help for that command
      # help:    you can use the option 'expanded' or the alias 'extended'
      # help:    `bot rules` will show only the specific rules for this channel.
      # help:    <https://github.com/MarioRuiz/slack-smart-bot#bot-help|more info>
      # help: command_id: :bot_help
      # help:


      # help: ----------------------------------------------
      # help: `Hi Bot`
      # help: `Hi Smart`
      # help: `Hello Bot` `Hola Bot` `Hallo Bot` `What's up Bot` `Hey Bot` `Hæ Bot`
      # help: `Hello THE_NAME_OF_THE_BOT`
      # help:    Bot starts listening to you if you are on a Bot channel
      # help:    After that if you want to avoid a single message to be treated by the smart bot, start the message by -
      # help:    Also apart of Hello you can use _Hallo, Hi, Hola, What's up, Hey, Hæ_
      # help:    <https://github.com/MarioRuiz/slack-smart-bot#how-to-access-the-smart-bot|more info>
      # help: command_id: :hi_bot
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
      # help: command_id: :bye_bot
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
        # help:     _add message `*Party* will start at *20:00* :tada:`_
        # help:     _add :heavy_exclamation_mark: message Pay attention all DB are on maintenance until 20:00 GMT_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#announcements|more info>
        # help: command_id: :add_announcement
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
        # help: command_id: :delete_announcement
        # help: 
      when /\A\s*(delete|remove)\s+(announcement|statement|declaration|message)\s+(\d+)\s*\z/i
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
        # help: command_id: :see_announcements
        # help: 
      when /\A\s*see\s+(red\s+|green\s+|white\s+|yellow\s+|:\w+:\s+)?(announcements|statements|declarations|messages)()\s*\z/i,
        /\A\s*see\s+(all\s+)?(announcements|statements|declarations|messages)()\s*\z/i,
        /\A\s*see\s+(red\s+|green\s+|white\s+|yellow\s+|:\w+:\s+)?(announcements|statements|declarations|messages)\s+#([\w\-]+)\s*\z/i,
        /\A\s*see\s+(red\s+|green\s+|white\s+|yellow\s+|:\w+:\s+)?(announcements|statements|declarations|messages)\s+<#(C\w+)\|.*>\s*\z/i

        type = $1.to_s.downcase.strip
        channel = $3.to_s

        see_announcements(user, type, channel)


        # help: ----------------------------------------------
        # help: `share messages /REGEXP/ on #CHANNEL`
        # help: `share messages "TEXT" on #CHANNEL`
        # xhelp: `share messages :EMOJI: on #CHANNEL`
        # help:     It will automatically share new messages published that meet the specified criteria.
        # xhelp:     In case :EMOJI: it will share the messages with the indicated reaction.
        # help:     SmartBot user and user adding the share need to be members on both channels.
        # help:     The Regexp will automatically add the parameters /im
        # help:     Only available on public channels.
        # help:  Examples:
        # help:     _share messages /(last\s+|previous\s+)sales\s+results\s+/ on #sales_
        # help:     _share messages "share post" on #announcements_
        # xhelp:     _share messages :tada: on #announcements_
        # xhelp:     _share messages :moneybag: from #sales_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#share-messages|more info>
        # help: command_id: :share_messages
        # help: 
      when /\A\s*share\s+messages\s+(\/.+\/|".+"|'.+')\s+on\s+<#\w+\|(.+)>\s*\z/i,
        /\A\s*share\s+messages\s+(\/.+\/|".+"|'.+')\s+on\s+<#(\w+)\|>\s*\z/,
        /\A\s*share\s+messages\s+(\/.+\/|".+"|'.+')\s+on\s+(.+)\s*\z/i
        condition = $1
        channel = $2
        channel.gsub!('#','') # for the case the channel name is in plain text including #
        channel = @channels_name[channel] if @channels_name.key?(channel)
        channel_from = @channels_name[dest]
        channel_to = channel
        share_messages(user, channel_from, channel_to, condition)

        # help: ----------------------------------------------
        # help: `see shares`
        # help:     It will display the active shares from this channel.
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#share-messages|more info>
        # help: command_id: :see_shares
        # help: 
      when /\A\s*see\s+shares\s*\z/i
        see_shares()

        # help: ----------------------------------------------
        # help: `delete share ID`
        # help:     It will delete the share id specified.
        # help:  Examples:
        # help:     _delete share 24_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#share-messages|more info>
        # help: command_id: :delete_share
        # help: 
      when /\A\s*(delete|remove)\s+share\s+(\d+)\s*\z/i
        share_id = $2
        delete_share(user, share_id)

        # help: ----------------------------------------------
        # help: `see statuses`
        # help: `see statuses #CHANNEL`
        # help: `see status EMOJI`
        # help: `see status EMOJI #CHANNEL`
        # help: `see status EMOJI1 EMOJI99`
        # help: `who is on vacation?`
        # help: `who are on vacation?`
        # help: `who is on EMOJI`
        # help: `who are on EMOJI #CHANNEL`
        # help: `who is on EMOJI1 EMOJI99`
        # help: `who are not on vacation?`
        # help: `who is not on EMOJI`
        # help:     It will display the current statuses of the members of the channel where you are calling the command or on the channel you supply.
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#see-statuses|more info>
        # help: command_id: :see_statuses
        # help: 
      when /\A\s*(see|get)\s+(statuses)()\s*\z/i,
        /\A\s*(see\s+status|get\s+status|who\s+is\s+on|who\s+are\s+on|who\s+is\s+not\s+on|who\s+are\s+not\s+on)\s+(:[\w\-\:\s]+:)\s*\??()\s*\z/i,
        /\A\s*(who\s+is\s+on|who\s+are\s+on|who\s+is\s+not\s+on|who\s+are\s+not\s+on)\s+(vacation|holiday)\s*\??()\s*\z/i,
        /\A\s*(see|get)\s+(statuses)\s+#([\w\-]+)\s*\z/i,
        /\A\s*(see\s+status|get\s+status|who\s+is\s+on|who\s+are\s+on|who\s+is\s+not\s+on|who\s+are\s+not\s+on)\s+(:[\w\-\:\s]+:)\s*\??\s+#([\w\-]+)\s*\z/i,
        /\A\s*(who\s+is\s+on|who\s+are\s+on|who\s+is\s+not\s+on|who\s+are\s+not\s+on)\s+(vacation|holiday)\s*\??\s+#([\w\-]+)\s*\z/i,
        /\A\s*(see|get)\s+(statuses)\s+<#(C\w+)\|.+>\s*\z/i,
        /\A\s*(see\s+status|get\s+status|who\s+is\s+on|who\s+is\s+not\s+on|who\s+are\s+on|who\s+are\s+not\s+on)\s+(:[\w\-\:\s]+:)\s*\??\s+<#(C\w+)\|.+>\s*\z/i,
        /\A\s*(who\s+is\s+on|who\s+is\s+not\s+on|who\s+are\s+on|who\s+are\s+not\s+on)\s+(vacation|holiday)\s*\??\s+<#(C\w+)\|.+>\s*\z/i

        not_on = $1.match?(/who\s+(is|are)\s+not\s+on/i)
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


        # help: ----------------------------------------------
        # help: `see favorite commands`
        # help: `see my favorite commands`
        # help: `favorite commands`
        # help: `my favorite commands`
        # help:     It will display the favorite commands.
        # help:     aliases for favorite: favourite, most used, fav
        # helpmaster:    You need to set stats to true to generate the stats when running the bot instance and get this info.
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#see-favorite-commands|more info>
        # help: command_id: :see_favorite_commands
        # help: 
      when /\A\s*(see\s+)?(my\s+)?(fav|favorite|favourite|most\s+used)\s+commands\s*\z/i
        only_mine = $2.to_s!=''
        see_favorite_commands(user, only_mine)

        # helpadmin: ----------------------------------------------
        # helpadmin: `add admin @user`
        # helpadmin:     It will add @user as an admin of the channel.
        # helpadmin:     Only creator of the channel, admins and master admins can use this command.
        # helpadmin:    <https://github.com/MarioRuiz/slack-smart-bot#bot-management|more info>
        # helpadmin: command_id: :add_admin
        # helpadmin: 
      when /\A\s*add\s+admin\s+<@(\w+)>\s*\z/i
        admin_user = $1
        add_admin(user, admin_user)

        # help: ----------------------------------------------
        # help: `see admins`
        # help: `show admins`
        # help: `who are admins?`
        # help:     It will show who are the admins of the channel.
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#bot-management|more info>
        # help: command_id: :see_admins
        # help: 
      when /\A\s*(see|show)\s+admins\s*\z/i, /\A\s*who\s+are\s+(the\s+)?admins\??\s*\z/i
        see_admins()

        # helpadmin: ----------------------------------------------
        # helpadmin: `remove admin @user`
        # helpadmin:     It will remove the admin privileges for @user on the channel.
        # helpadmin:     Only creator of the channel, admins and master admins can use this command.
        # helpadmin:    <https://github.com/MarioRuiz/slack-smart-bot#bot-management|more info>
        # helpadmin: command_id: :remove_admin
        # helpadmin: 
      when /\A\s*(remove|delete)\s+admin\s+<@(\w+)>\s*\z/i
        admin_user = $2
        remove_admin(user, admin_user)

        # helpadmin: ----------------------------------------------
        # helpadmin: `see command ids`
        # helpadmin:     It will display all available command ids.
        # helpadmin:     The command id can be used on `bot stats command COMMAND_ID`, `allow access COMMAND_ID` and `deny access COMMAND_ID`
        # helpadmin:     Only creator of the channel, admins and master admins can use this command.
        # helpadmin:    <https://github.com/MarioRuiz/slack-smart-bot#bot-management|more info>
        # helpadmin: command_id: :see_command_ids
        # helpadmin: 
      when /\A\s*(see|display)\s+command(\s+|_)ids?\s*\z/i
        see_command_ids()

        # help: ----------------------------------------------
        # help: `poster MESSAGE`
        # help: `poster :EMOTICON_TEXT: MESSAGE`
        # help: `poster :EMOTICON_TEXT: :EMOTICON_BACKGROUND: MESSAGE`
        # help: `poster MINUTESm MESSAGE`
        # help:     It will create a poster with the message supplied. By default will be autodeleted 1 minute later.
        # help:     If you want the poster to be permanent then use the command `pposter`
        # help:     If minutes supplied then it will be deleted after the minutes specified. Maximum value 60.
        # help:     To see the messages on a mobile phone put the phone on landscape mode
        # help:     Max 15 characters. If the message is longer than that won't be treat it.
        # help:     Only letters from a to z, 0 to 9 and the chars: ? ! - + =
        # help:     To be displayed correctly use words with no more than 6 characters
        # help:     Examples:
        # help:            _poster nice work!_
        # help:            _poster :heart: nice work!_
        # help:            _poster :mac-spinning-wheel: :look: love!_
        # help:            _poster 25m :heart: woah!_
        # help: command_id: :poster
        # help: 
      when /\A()poster\s+(\d+m\s+)?(:[^:]+:)\s+(:[^:]+:)(.+)\s*\z/i, /\A()poster\s+(\d+m\s+)?(:.+:)\s+()(.+)\s*\z/i, /\A()poster\s+(\d+m\s+)?()()(.+)\s*\z/i,
        /\A(p)poster\s+()(:[^:]+:)\s+(:[^:]+:)(.+)\s*\z/i, /\A(p)poster\s+()(:.+:)\s+()(.+)\s*\z/i, /\A(p)poster\s+()()()(.+)\s*\z/i
        permanent = $1.to_s != ''
        minutes = $2.to_s
        emoticon_text = $3
        emoticon_bg = $4
        text = $5
        minutes = minutes.scan(/(\d+)/).join
        
        if minutes == ''
          minutes = 1
        elsif minutes.to_i > 60
          minutes = 60
        end
        
        save_stats :poster
        if text.to_s.gsub(/\s+/, '').length > 15
          respond "Too long. Max 15 chars", :on_thread
        else
          poster(permanent, emoticon_text, emoticon_bg, text, minutes)
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