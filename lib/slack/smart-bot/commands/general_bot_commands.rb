class SlackSmartBot

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
      # help: `<bot help`
      # help: `<bot rules`
      # help:    it will display this help. For a more detailed help call `bot help expanded` or `bot rules expanded`.
      # help:    if COMMAND supplied just help for that command
      # help:    you can use the option 'expanded' or the alias 'extended'
      # help:    `bot rules` will show only the specific rules for this channel.
      # help:    if added '<' at the beginning the help will be sent as a snippet on MD format. Click on the icon for 'Open in new window' to see it on a browser.
      # help:      You can install this extension in Google Chrome to view it: https://chromewebstore.google.com/detail/medapdbncneneejhbgcjceippjlfkmkg
      # help:    <https://github.com/MarioRuiz/slack-smart-bot#bot-help|more info>
      # help: command_id: :bot_help
      # help:

      # help: ----------------------------------------------
      # help: `get smartbot readme`
      # help: `smartbot readme`
      # help: `readme smartbot`
      # help:      It will send the README.md file to the channel.
      # help:      To open the file on a browser click on the icon for 'Open in new window'
      # help:      You can install this extension in Google Chrome to view it: https://chromewebstore.google.com/detail/medapdbncneneejhbgcjceippjlfkmkg
      # help: command_id: :get_smartbot_readme
      # help:
      when /^\A*(get\s+)?smartbot\s+readme\s*\z/i, /^\A*readme\s+smartbot\s*\z/i
        get_smartbot_readme(dest)

        # help: ----------------------------------------------
        # help: `for NUMBER times every NUMBER minutes COMMAND`
        # help: `for NUMBER times every NUMBER seconds COMMAND`
        # help: `NUMBER times every NUMBER minutes COMMAND`
        # help: `NUMBER times every NUMBER seconds COMMAND`
        # help:    It will run the command every NUMBER minutes or seconds for NUMBER times.
        # help:    max 24 times. min every 10 seconds. max every 60 minutes.
        # help:    Call `quit loop LOOP_ID` to stop the loop.
        # help:       aliases for minutes: m, minute, minutes
        # help:       aliases for seconds: s, sc, second, seconds
        # help:  Examples:
        # help:       _for 5 times every 1 minute ^ruby puts Time.now_
        # help:       _10 times every 30s !ruby puts Time.now_
        # help:       _24 times every 60m !get sales today_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#loops|more info>
        # help: command_id: :create_loop
        # help:

        # help: ----------------------------------------------
        # help: `quit loop LOOP_ID`
        # help:    It will stop the loop with the id LOOP_ID.
        # help:    Only the user who created the loop or an admin can stop it.
        # help:       aliases for loop: iterator, iteration
        # help:       aliases for quit: stop, exit, kill
        # help:  Examples:
        # help:       _quit loop 1_
        # help:       _stop iterator 12_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#loops|more info>
        # help: command_id: :quit_loop
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
        bye_bot(dest, user, display_name)

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
        permanent = $1.to_s != ""
        minutes = $2.to_s
        emoticon_text = $3
        emoticon_bg = $4
        text = $5
        minutes = minutes.scan(/(\d+)/).join

        if minutes == ""
          minutes = 1
        elsif minutes.to_i > 60
          minutes = 60
        end

        save_stats :poster
        if text.to_s.gsub(/\s+/, "").length > 15
          respond "Too long. Max 15 chars", :on_thread
        else
          poster(permanent, emoticon_text, emoticon_bg, text, minutes)
        end

        # help: ----------------------------------------------
        # help: >*<https://github.com/MarioRuiz/slack-smart-bot#announcements|ANNOUNCEMENTS>*
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
           /\A\s*(add|create)\s+(:[\w\-]+:)\s+(announcement|statement|declaration|message)\s+(.+)\s*\z/i
        type = $2.to_s.downcase.strip
        type = "white" if type == ""
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
      when /\A\s*see\s+(red\s+|green\s+|white\s+|yellow\s+|:[\w\-]+:\s+)?(announcements|statements|declarations|messages)()\s*\z/i,
           /\A\s*see\s+(all\s+)?(announcements|statements|declarations|messages)()\s*\z/i,
           /\A\s*see\s+(red\s+|green\s+|white\s+|yellow\s+|:[\w\-]+:\s+)?(announcements|statements|declarations|messages)\s+#([\w\-]+)\s*\z/i,
           /\A\s*see\s+(red\s+|green\s+|white\s+|yellow\s+|:[\w\-]+:\s+)?(announcements|statements|declarations|messages)\s+<#(\w+)\|.*>\s*\z/i
        type = $1.to_s.downcase.strip
        channel = $3.to_s

        see_announcements(user, type, channel)

        # help: ----------------------------------------------
        # help: >*<https://github.com/MarioRuiz/slack-smart-bot#share-messages|SHARE MESSAGES>*
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
        channel.gsub!("#", "") # for the case the channel name is in plain text including #
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
        # help: >*<https://github.com/MarioRuiz/slack-smart-bot#see-statuses|SEE STATUSES>*
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
        # help: `who is available?`
        # help:     It will display the current statuses of the members of the channel where you are calling the command or on the channel you supply.
        # help:     In case of `who is available?` will show members of the channel that are on line and not on a meeting or vacation or sick.
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#see-statuses|more info>
        # help: command_id: :see_statuses
        # help:
      when /\A\s*(see|get)\s+(statuses)()\s*\z/i,
           /\A\s*(see\s+status|get\s+status|who\s+is\s+on|who\s+are\s+on|who\s+is\s+not\s+on|who\s+are\s+not\s+on)\s+(:[\w\-\:\s]+:)\s*\??()\s*\z/i,
           /\A\s*(who\s+is\s+on|who\s+are\s+on|who\s+is\s+not\s+on|who\s+are\s+not\s+on)\s+(vacation|holiday)\s*\??()\s*\z/i,
           /\A\s*(who\s+is|who\s+are)\s+(available|active)\s*\??()\s*\z/i,
           /\A\s*(see|get)\s+(statuses)\s+#([\w\-]+)\s*\z/i,
           /\A\s*(see\s+status|get\s+status|who\s+is\s+on|who\s+are\s+on|who\s+is\s+not\s+on|who\s+are\s+not\s+on)\s+(:[\w\-\:\s]+:)\s*\??\s+#([\w\-]+)\s*\z/i,
           /\A\s*(who\s+is|who\s+are)\s+(available|active)\s*\??\s+#([\w\-]+)\s*\z/i,
           /\A\s*(who\s+is|who\s+are)\s+(available|active)\s*\??\s+<#(\w+)\|.*>\s*\z/i,
           /\A\s*(who\s+is\s+on|who\s+are\s+on|who\s+is\s+not\s+on|who\s+are\s+not\s+on)\s+(vacation|holiday)\s*\??\s+#([\w\-]+)\s*\z/i,
           /\A\s*(see|get)\s+(statuses)\s+<#(\w+)\|.*>\s*\z/i,
           /\A\s*(see\s+status|get\s+status|who\s+is\s+on|who\s+is\s+not\s+on|who\s+are\s+on|who\s+are\s+not\s+on)\s+(:[\w\-\:\s]+:)\s*\??\s+<#(\w+)\|.*>\s*\z/i,
           /\A\s*(who\s+is\s+on|who\s+is\s+not\s+on|who\s+are\s+on|who\s+are\s+not\s+on)\s+(vacation|holiday)\s*\??\s+<#(\w+)\|.*>\s*\z/i
        not_on = $1.match?(/who\s+(is|are)\s+not\s+on/i)
        type = $2.downcase
        channel = $3.to_s
        if type == "statuses"
          types = []
        elsif type == "vacation" or type == "holiday"
          types = [":palm_tree:"]
        elsif type == "available" or type == "active"
          types = ["available"]
        else
          type.gsub!(" ", "")
          type.gsub!("::", ": :")
          types = type.split(" ")
        end
        see_statuses(user, channel, types, dest, not_on)

        # help: ----------------------------------------------
        # help: >*<https://github.com/MarioRuiz/slack-smart-bot#see-favorite-commands|SEE FAVORITE COMMANDS>*
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
        only_mine = $2.to_s != ""
        see_favorite_commands(user, only_mine)

        # help: ----------------------------------------------
        # help: >*<https://github.com/MarioRuiz/slack-smart-bot#control-who-has-access-to-a-command|CONTROL ACCESS TO COMMANDS>*
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
      when /\A\s*(see|display|get)\s+command(\s+|_)ids?\s*\z/i
        see_command_ids()

        # helpadmin: ----------------------------------------------
        # helpadmin: `allow access COMMAND_ID`
        # helpadmin: `allow access COMMAND_ID @user1 @user99`
        # helpadmin:     It will allow the specified command to be used on the channel.
        # helpadmin:     If @user specified, only those users will have access to the command.
        # helpadmin:     Only admins of the channel can use this command
        # helpadmin:    <https://github.com/MarioRuiz/slack-smart-bot#control-who-has-access-to-a-command|more info>
        # helpadmin: command_id: :allow_access
        # helpadmin:
      when /\A\s*(allow|give)\s+access\s+(\w+)\s+(.+)\s*\z/i, /\A\s*(allow|give)\s+access\s+(\w+)()\s*\z/i
        command_id = $2.downcase
        opt = $3.to_s.split(" ")
        allow_access(user, command_id, opt)

        # helpadmin: ----------------------------------------------
        # helpadmin: `deny access COMMAND_ID`
        # helpadmin:     It won't allow the specified command to be used on the channel.
        # helpadmin:     Only admins of the channel can use this command
        # helpadmin:    <https://github.com/MarioRuiz/slack-smart-bot#control-who-has-access-to-a-command|more info>
        # helpadmin: command_id: :deny_access
        # helpadmin:
      when /\A\s*deny\s+access(\s+rights)?\s+(\w+)\s*\z/i
        command_id = $2.downcase
        deny_access(user, command_id)

        # help: ----------------------------------------------
        # help: `see access COMMAND_ID`
        # help:     It will show the access rights for the specified command.
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#control-who-has-access-to-a-command|more info>
        # help: command_id: :see_access
        # help:
      when /\A\s*(see|show)\s+access(\s+rights)?\s+(.+)\s*\z/i
        command_id = $3.downcase
        see_access(command_id)

        # help: ----------------------------------------------
        # help: >*<https://github.com/MarioRuiz/slack-smart-bot#teams|TEAMS>*
        # help: `add team TEAM_NAME members #TEAM_CHANNEL CHANNEL_TYPE #CHANNEL1 #CHANNEL99 : INFO`
        # help: `add team TEAM_NAME MEMBER_TYPE @USER1 @USER99 CHANNEL_TYPE #CHANNEL1 #CHANNEL99 : INFO`
        # help: `add team TEAM_NAME MEMBER_TYPE1 @USER1 @USER99 MEMBER_TYPE99 @USER1 @USER99 CHANNEL_TYPE1 #CHANNEL1 #CHANNEL99 CHANNEL_TYPE99 #CHANNEL1 #CHANNEL99 : INFO`
        # help:     It will add a team with the info supplied.
        # help:     TEAM_NAME, TYPE: one word, a-z, A-Z, 0-9, - and _
        # help:     In case it is supplied a channel with type 'members' the members of that channel would be considered members of the team. The SmartBot needs to be a member of the channel.
        # help:  Examples:
        # help:     _add team sales members #sales support #sales-support public #sales-ff : Contact us if you need anything related to Sales. You can also send us an email at sales@ffxaja.com_
        # help:     _add team Sales manager @ann qa @peter @berglind dev @john @sam @marta members #sales support #sales-support public #sales-ff : Contact us if you need anything related to Sales. You can also send us an email at sales@ffxaja.com_
        # help:     _add team devweb qa @jim dev @johnja @cooke @luisa members #devweb support #devweb-support : We take care of the website_
        # help:     _add team sandex manager @sarah members #sandex : We take care of the sand_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#teams|more info>
        # help: command_id: :add_team
        # help:
      when /\A\s*add\s+team\s+([\w\-]+)\s+([^:]+)\s*:\s+(.+)\s*\z/im, /\A\s*add\s+([\w\-]+)\s+team\s+([^:]+)\s*:\s+(.+)\s*\z/im
        name = $1.downcase
        options = $2
        info = Thread.current[:command_orig].to_s.gsub("\u00A0", " ").scan(/^[^:]+:\s*(.+)\s*$/im).join
        add_team(user, name, options, info)

        # help: ----------------------------------------------
        # help: `add TYPE to TEAM_NAME team : MESSAGE`
        # help: `add private TYPE to TEAM_NAME team : MESSAGE`
        # help: `add personal TYPE to TEAM_NAME team : MESSAGE`
        # help: `add TYPE to TEAM_NAME team TOPIC : MESSAGE`
        # help: `add private TYPE to TEAM_NAME team TOPIC : MESSAGE`
        # help: `add personal TYPE to TEAM_NAME team TOPIC : MESSAGE`
        # help:     It will add a memo to the team. The memos will be displayed with the team info.
        # help:     Only team members can add a memo.
        # help:     TYPE: memo, note, issue, task, feature, bug, jira, github
        # help:     TOPIC: one word, a-z, A-Z, 0-9, - and _
        # help:     If private then the memo will be only displayed to team members on a DM or the members channel.
        # help:     If personal then the memo will be only displayed to the creator on a DM.
        # help:     In case jira type supplied:
        # help:       The message should be an JQL URL, JQL string or an issue URL.
        # help:       To be able to use it you need to specify on the SmartBot settings the credentials.
        # help:       In case no TOPIC is supplied then it will create automatically the topics from the labels specified on every JIRA issue
        # help:     In case github type supplied:
        # help:       The message should be a github URL. You can filter by state (open/closed/all) and labels
        # help:       To be able to use it you need to specify on the SmartBot settings the github token.
        # help:       In case no TOPIC is supplied then it will create automatically the topics from the labels specified on every Github issue
        # help:  Examples:
        # help:     _add memo to sales team : Add tests for Michigan feature_
        # help:     _add private note to sales team : Bills will need to be deployed before Friday_
        # help:     _add memo to dev team web : Check last version_
        # help:     _add private bug to dev team SRE : Logs should not be accessible from outside VPN_
        # help:     _add memo sales team : Add tests for Michigan feature_
        # help:     _add memo team sales: Add tests for Michigan feature_
        # help:     _add personal memo team sales: Check my vacations_
        # help:     _add jira to sales team : labels = SalesT AND status != Done_
        # help:     _add github to sales team : PeterBale/SalesBoom/issues?state=open&labels=bug_
        # help:     _add github to sales team dev: PeterBale/DevProject/issues/71_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#teams|more info>
        # help: command_id: :add_memo_team
        # help:
      when /\A\s*add\s+(private\s+|personal\s+)?(memo|note|issue|task|feature|bug|jira|github)\s+(to\s+)?team\s+([\w\-]+)\s*([^:]+)?\s*:\s+(.+)\s*\z/im,
           /\A\s*add\s+(private\s+|personal\s+)?(memo|note|issue|task|feature|bug|jira|github)\s+(to\s+)?([\w\-]+)\s+team\s*([^:]+)?\s*:\s+(.+)\s*\z/im
        privacy = $1.to_s.strip.downcase
        type = $2.downcase
        team_name = $4.downcase
        topic = $5.to_s.strip
        message = Thread.current[:command_orig].to_s.gsub("\u00A0", " ").scan(/^[^:]+:\s*(.+)\s*$/im).join
        add_memo_team(user, privacy, team_name, topic, type, message)

        # help: ----------------------------------------------
        # help: `delete memo ID from TEAM_NAME team`
        # help:     It will delete the supplied memo ID on the team specified.
        # help:     aliases for memo: note, issue, task, feature, bug, jira, github
        # help:     You have to be a member of the team, the creator or a Master admin to be able to delete a memo.
        # help:  Examples:
        # help:     _delete memo 32 from sales team_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#teams|more info>
        # help: command_id: :delete_memo_team
        # help:
      when /\A\s*(delete|remove)\s+(memo|note|issue|task|feature|bug|jira|github)\s+(\d+)\s+(from|on)\s+team\s+([\w\-]+)\s*\z/i,
           /\A\s*(delete|remove)\s+(memo|note|issue|task|feature|bug|jira|github)\s+(\d+)\s+(from|on)\s+([\w\-]+)\s+team\s*\z/i
        memo_id = $3
        team_name = $5.downcase
        delete_memo_team(user, team_name, memo_id)

        # help: ----------------------------------------------
        # help: `set memo ID on TEAM_NAME team STATUS`
        # help: `set STATUS on memo ID TEAM_NAME team`
        # help:     It will assign to the ID specified the emoticon status indicated.
        # help:     aliases for memo: note, issue, task, feature, bug
        # help:     This command will be only for memo, note, issue, task, feature, bug. Not for jira or github.
        # help:     You have to be a member of the team, the creator or a Master admin to be able to set a status.
        # help:  Examples:
        # help:     _set memo 32 on sales team :runner:_
        # help:     _set bug 7 on team sales :heavy_check_mark:_
        # help:     _set :runner: on memo 6 sales team_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#teams|more info>
        # help: command_id: :set_memo_status
        # help:
      when /\A\s*(set)\s+(memo|note|issue|task|feature|bug)\s+(\d+)\s+on\s+team\s+([\w\-]+)\s+(:[\w\-]+:)\s*\z/i,
           /\A\s*(set)\s+(memo|note|issue|task|feature|bug)\s+(\d+)\s+on\s+([\w\-]+)\s+team\s+(:[\w\-]+:)\s*\z/i
        memo_id = $3
        team_name = $4.downcase
        status = $5
        set_memo_status(user, team_name, memo_id, status)
      when /\A\s*(set)\s+(:[\w\-]+:)\s+on\s+(memo|note|issue|task|feature|bug)\s+(\d+)\s+team\s+([\w\-]+)\s*\z/i,
           /\A\s*(set)\s+(:[\w\-]+:)\s+on\s+(memo|note|issue|task|feature|bug)\s+(\d+)\s+([\w\-]+)\s+team\s*\z/i
        memo_id = $4
        team_name = $5.downcase
        status = $2
        set_memo_status(user, team_name, memo_id, status)

        # help: ----------------------------------------------
        # help: `team TEAM_NAME memo ID MESSAGE`
        # help: `TEAM_NAME team memo ID MESSAGE`
        # help:     It will add a comment to the memo ID specified on the team specified.
        # help:     aliases for memo: note, issue, task, feature, bug
        # help:  Examples:
        # help:     _sales team memo 32 I have a question, is there any public data published?_
        # help:     _dev team task 77 putting this on hold until we get more info_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#teams|more info>
        # help: command_id: :add_memo_team_comment
        # help:
      when /\A\s*team\s+([\w\-]+)\s+(memo|note|issue|task|feature|bug)\s+(\d+)\s+(.+)\s*\z/im,
           /\A\s*([\w\-]+)\s+team\s+(memo|note|issue|task|feature|bug)\s+(\d+)\s+(.+)\s*\z/im
        team_name = $1.downcase
        memo_id = $3
        message = $4.to_s.strip
        add_memo_team_comment(user, team_name, memo_id, message)

        # help: ----------------------------------------------
        # help: `team TEAM_NAME memo ID`
        # help: `TEAM_NAME team memo ID`
        # help:     It will show the memo ID specified on the team specified.
        # help:     aliases for memo: note, issue, task, feature, bug
        # help:  Examples:
        # help:     _sales team memo 32_
        # help:     _dev team task 77_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#teams|more info>
        # help: command_id: :see_memo_team
        # help:
      when /\A\s*team\s+([\w\-]+)\s+(memo|note|issue|task|feature|bug)\s+(\d+)\s*\z/i,
           /\A\s*([\w\-]+)\s+team\s+(memo|note|issue|task|feature|bug)\s+(\d+)\s*\z/i
        team_name = $1.downcase
        memo_id = $3
        see_memo_team(user, team_name, memo_id)

        # help: ----------------------------------------------
        # help: `see teams`
        # help: `see team TEAM_NAME`
        # help: `team TEAM_NAME`
        # help: `TEAM_NAME team`
        # help: `TEAM_NAME team TOPIC`
        # help: `which team @USER`
        # help: `which team #CHANNEL`
        # help: `which team TEXT_TO_SEARCH_ON_INFO`
        # help: `which team does @USER belongs to?`
        # help:     It will display all teams or the team specified.
        # help:     In case a specific team it will show also the availability of the members.
        # help:     TOPIC: It will filter members, channels and memos by topic.
        # help:  Examples:
        # help:     _see teams_
        # help:     _see team Sales_
        # help:     _Dev team_
        # help:     _Sales team dev_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#teams|more info>
        # help: command_id: :see_teams
        # help:

        # help: ----------------------------------------------
        # help: `update team TEAM_NAME NEW_TEAM_NAME`
        # help: `update team TEAM_NAME : NEW_INFO`
        # help: `update team TEAM_NAME add MEMBER_TYPE @USER`
        # help: `update team TEAM_NAME add CHANNEL_TYPE #CHANNEL`
        # help: `update team TEAM_NAME delete MEMBER_TYPE @USER`
        # help: `update team TEAM_NAME delete CHANNEL_TYPE #CHANNEL`
        # help: `update team TEAM_NAME delete @USER`
        # help: `update team TEAM_NAME delete #CHANNEL`
        # help:     It will update a team with the info supplied.
        # help:     You have to be a member of the team, the creator or a Master admin to be able to update a team.
        # help:  Examples:
        # help:     _update team sales salesff_
        # help:     _update team salesff : Support for customers_
        # help:     _update sales team delete @sarah @peter_
        # help:     _update team sales delete public #sales_
        # help:     _update team sales delete #sales_support_
        # help:     _update sales team add public #salesff_
        # help:     _update sales team add qa @john @ben @ana_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#teams|more info>
        # help: command_id: :update_team
        # help:
      when /\A\s*update\s+team\s+([\w\-]+)\s+([\w\-]+)\s*\z/i, /\A\s*update\s+([\w\-]+)\s+team\s+([\w\-]+)\s*\z/i
        name = $1.downcase
        new_name = $2.downcase
        update_team(user, name, new_name: new_name)
      when /\A\s*update\s+team\s+([\w\-]+)\s*:\s+(.+)\s*\z/im, /\A\s*update\s+([\w\-]+)\s+team\s*:\s+(.+)\s*\z/im
        name = $1.downcase
        new_info = Thread.current[:command_orig].to_s.gsub("\u00A0", " ").scan(/^[^:]+:\s*(.+)\s*$/im).join
        update_team(user, name, new_info: new_info)
      when /\A\s*update\s+team\s+([\w\-]+)\s+(delete|remove)\s+(.+)\s*\z/i, /\A\s*update\s+([\w\-]+)\s+team\s+(delete|remove)\s+(.+)\s*\z/i
        name = $1.downcase
        delete_opts = $3
        update_team(user, name, delete_opts: delete_opts)
      when /\A\s*update\s+team\s+([\w\-]+)\s+add\s+(.+)\s*\z/i, /\A\s*update\s+([\w\-]+)\s+team\s+add\s+(.+)\s*\z/i
        name = $1.downcase
        add_opts = $2
        update_team(user, name, add_opts: add_opts)

        # help: ----------------------------------------------
        # help: `ping team TEAM_NAME MEMBER_TYPE MESSAGE`
        # help: `contact team TEAM_NAME MEMBER_TYPE MESSAGE`
        # help:     ping: It will send the MESSAGE naming all available members of the MEMBER_TYPE supplied.
        # help:     contact: It will send the MESSAGE naming all members of the MEMBER_TYPE supplied.
        # help:     In case MEMBER_TYPE is 'all' it will name 10 random members of the team
        # help:  Examples:
        # help:     _ping team sales development How is the status on the last feature_
        # help:     _contact team sales qa Please finish testing of dev02 feature before noon_
        # help:     _contact team qa all Check the test failures please_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#teams|more info>
        # help: command_id: :ping_team
        # help: command_id: :contact_team
        # help:
      when /\A\s*(contact|ping)\s+team\s+([\w\-]+)\s+([\w\-]+)\s+(.+)\s*\z/im, /\A\s*(contact|ping)\s+([\w\-]+)\s+team\s+([\w\-]+)\s+(.+)\s*\z/im
        type = $1.downcase.to_sym
        name = $2.downcase
        member_type = $3.downcase
        message = Thread.current[:command_orig].to_s.gsub("\u00A0", " ").gsub(/\A\^/, "").gsub(/\A!!/, "").gsub(/\A!/, "").scan(/\A\s*[\w]+\s+\w+\s+team\s+[\w\-]+\s+(.+)\s*\z/im).join
        if message == ""
          message = Thread.current[:command_orig].to_s.gsub("\u00A0", " ").gsub(/\A\^/, "").gsub(/\A!!/, "").gsub(/\A!/, "").scan(/\A\s*[\w]+\s+team\s+\w+\s+[\w\-]+\s+(.+)\s*\z/im).join
        end
        ping_team(user, type, name, member_type, message)

        # help: ----------------------------------------------
        # help: `delete team TEAM_NAME`
        # help:     It will delete the supplied team.
        # help:     You have to be a member of the team, the creator or a Master admin to be able to delete a team.
        # help:  Examples:
        # help:     _delete team sales_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#teams|more info>
        # help: command_id: :delete_team
        # help:
      when /\A\s*(delete|remove)\s+team\s+([\w\-]+)\s*\z/i, /\A\s*(delete|remove)\s+([\w\-]+)\s+team\s*\z/i
        name = $2.downcase
        delete_team(user, name)
      when /\A\s*(see\s+)?(vacations|time\s+off)\s+team\s+([\w\-]+)\s*(\d\d\d\d\/\d\d\/\d\d)?\s*\z/i,
           /\A\s*(see\s+)?(vacations|time\s+off)\s+([\w\-]+)\s+team\s*(\d\d\d\d\/\d\d\/\d\d)?\s*\z/i,
           /\A\s*(see\s+)?(vacations|time\s+off)\s+team\s+([\w\-]+)\s*(\d\d\d\d-\d\d-\d\d)?\s*\z/i,
           /\A\s*(see\s+)?(vacations|time\s+off)\s+([\w\-]+)\s+team\s*(\d\d\d\d-\d\d-\d\d)?\s*\z/i
        team_name = $3.downcase
        date = $4.to_s
        date = Date.today.strftime("%Y/%m/%d") if date.empty?
        react :running
        see_vacations_team(user, team_name, date)
        unreact :running
      when /\A\s*(which|search)\s+teams?\s+(is\s+)?(.+)\??\s*\z/i, /\A\s*which\s+team\s+does\s+()()(.+)\s+belongs\s+to\??\s*\z/i
        search = $3.to_s.downcase
        see_teams(user, "", search)
      when /\A\s*see\s+teams?\s*([\w\-]+)?\s*()\z/i,
           /\A\s*team\s+([\w\-]+)\s*()\z/i, /\A\s*([\w\-]+)\s+team\s*()\z/i,
           /\A\s*team\s+([\w\-]+)\s+([\w\-]+)\z/i, /\A\s*([\w\-]+)\s+team\s+([\w\-]+)\z/i,
           /\A\s*see\s+all\s+teams\s*()()\z/i
        name = $1.to_s.downcase
        type = $2.to_s.downcase
        see_teams(user, name, ttype: type)

        # help: ----------------------------------------------
        # help: `see MEMO_TYPE from TEAM_NAME team`
        # help: `see MEMO_TYPE from TEAM_NAME team TOPIC`
        # help: `see all memos from TEAM_NAME team`
        # help: `see all memos from TEAM_NAME team TOPIC`
        # help:     It will show the memos of the team.
        # help:     If TOPIC is supplied it will show the memos of the topic.
        # help:     MEMO_TYPE: memos, notes, issues, tasks, features, bugs, jira, github. In case of 'all memos' will display all of any type.
        # help:  Examples:
        # help:     _see memos from sales team_
        # help:     _see bugs from sales team_
        # help:     _see all memos from sales team webdev_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#teams|more info>
        # help: command_id: :see_memos_team
        # help:
      when /\A\s*(see\s+)?(memo|note|issue|task|feature|bug|jira|github|all\s+memo)s?\s+(from\s+)?([\w\-]+)\s+team(.*)\s*\z/i,
           /\A\s*(see\s+)?(memo|note|issue|task|feature|bug|jira|github|all\s+memo)s?\s+(from\s+)?team\s+([\w\-]+)(.*)\s*\z/i
        type = $2.downcase.to_sym
        name = $4.downcase
        topic = $5.strip
        see_memos_team(user, type: type, name: name, topic: topic)

        # help: ----------------------------------------------
        # help: >*<https://github.com/MarioRuiz/slack-smart-bot#time-off-management|TIME OFF MANAGEMENT>*
        # help: `add vacation from YYYY/MM/DD to YYYY/MM/DD`
        # help: `add vacation YYYY/MM/DD`
        # help: `add sick from YYYY/MM/DD to YYYY/MM/DD`
        # help: `add sick YYYY/MM/DD`
        # help: `add sick child YYYY/MM/DD`
        # help: `I'm sick today`
        # help: `I'm on vacation today`
        # help:     It will add the supplied period to your plan.
        # help:     Instead of YYYY/MM/DD you can use 'today' or 'tomorrow' or 'next week'
        # help:     To see your plan call `see my time off`
        # help:     If you want to see the vacation plan for the team `see team NAME`
        # help:     Also you can see the vacation plan for the team for a specific period: `vacations team NAME YYYY/MM/DD`
        # help:     The SmartBot will automatically set the users status to :palm_tree:, :baby: or :face_with_thermometer: and the expiration date.
        # help:  Examples:
        # help:     _add vacation from 2022/10/01 to 2022/10/22_
        # help:     _add sick 2022/08/22_
        # help:     _add vacation tomorrow_
        # help:     _I'll be on vacation next week_
        # help:     _add sick baby today_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#time-off-management|more info>
        # help: command_id: :add_vacation
        # help:
      when /\A\s*(add)\s+(sick|vacation|sick\s+baby|sick\s+child)\s+from\s+(\d\d\d\d\/\d\d\/\d\d)\s+to\s+(\d\d\d\d\/\d\d\/\d\d)\s*\z/i,
           /\A\s*(add)\s+(sick|vacation|sick\s+baby|sick\s+child)\s+from\s+(\d\d\d\d-\d\d-\d\d)\s+to\s+(\d\d\d\d-\d\d-\d\d)\s*\z/i,
           /\A\s*(add)\s+(sick|vacation|sick\s+baby|sick\s+child)\s+(\d\d\d\d-\d\d-\d\d)()\s*\z/i,
           /\A\s*(add)\s+(sick|vacation|sick\s+baby|sick\s+child)\s+(\d\d\d\d\/\d\d\/\d\d)()\s*\z/i,
           /\A\s*(add)\s+(sick|vacation|sick\s+baby|sick\s+child)\s+(today|tomorrow|next\sweek)()\s*\z/i,
           /\A\s*(I'm|I\s+am|I'll\s+be|I\s+will\s+be)\s+(sick|on\s+vacation)\s+(today|tomorrow|next\sweek)()\s*\z/i
        type = $2
        from = $3.downcase
        to = $4
        type = "vacation" if type.match?(/vacation/)
        add_vacation(user, type, from, to)

        # help: ----------------------------------------------
        # help: `remove vacation ID`
        # help: `remove vacation period ID`
        # help: `remove sick period ID`
        # help: `remove time off period ID`
        # help: `delete vacation ID`
        # help:     It will remove the specified period from your vacations/sick periods.
        # help:  Examples:
        # help:     _remove vacation 20_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#time-off-management|more info>
        # help: command_id: :remove_vacation
        # help:
      when /\A\s*(delete|remove)\s+(vacation|sick|time\s+off)(\s+period)?\s+(\d+)\s*\z/i
        vacation_id = $4.to_i
        remove_vacation(user, vacation_id)

        # help: ----------------------------------------------
        # help: `see my vacations`
        # help: `see my time off`
        # help: `see vacations @USER`
        # help: `see my vacations YEAR`
        # help: `time off`
        # help:     It will display current and past time off.
        # help:     If you call this command on a DM, it will show your vacations for the year on a calendar.
        # help:     see: (optional)
        # help: Examples:
        # help:     _see my vacations_
        # help:     _see my time off 2022_
        # help:     _see vacations @john_
        # help:     _time off 2023_
        # help:     _time off @johan 2024_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#time-off-management|more info>
        # help: command_id: :see_vacations
        # help:
      when /\A\s*(see\s+)?(my\s+)?vacations\s*()\s*(\d{4})?\s*\z/i,
           /\A\s*(see\s+)?(my\s+)?time\s*off\s*()\s*(\d{4})?\s*\z/i,
           /\A\s*(see\s+)()?time\s*off\s+<@(\w+)>\s*\s*(\d{4})?\s*\z/i,
           /\A\s*(see\s+)()?vacations\s+<@(\w+)>\s*(\d{4})?\s*\z/i
        from_user = $3
        year = $4
        react :running
        see_vacations(user, dest, from_user: from_user, year: year)
        unreact :running

        # help: ----------------------------------------------
        # help: `vacations team NAME`
        # help: `time off team NAME`
        # help: `vacations team NAME YYYY/MM/DD`
        # help: `time off team NAME YYYY/MM/DD`
        # help:     It will display the time off plan for the team specified.
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#time-off-management|more info>
        # help: command_id: :see_vacations_team
        # help:

        # help: ----------------------------------------------
        # help: `public holidays COUNTRY`
        # help: `public holidays COUNTRY/STATE DATE`
        # help: `calendar COUNTRY`
        # help: `calendar COUNTRY/STATE DATE`
        # help:     It will display the public holidays for the country specified.
        # help:     If calendar then it will show the calendar for the country specified.
        # help:     STATE: optional. If not specified, it will return all the holidays for the country.
        # help:     DATE: optional. It can be supplied as YYYY or YYYY-MM or YYYY-MM-DD. If not specified, it will return all the holidays for current year.
        # help: Examples:
        # help:     _public holidays United States_
        # help:     _public holidays United States/California_
        # help:     _public holidays United States/California 2023_
        # help:     _public holidays Iceland 2023-12_
        # help:     _public holidays India 2023-12-25_
        # help:     _calendar United States/California_
        # help: command_id: :public_holidays
        # help: command_id: :calendar_country
        # help:
      when /\A\s*(public\s+)?(holiday?|vacation|calendar)s?\s+(in\s+|on\s+)?([a-zA-Z\s]+)()()()()\s*\z/i,
           /\A\s*(public\s+)?(holiday?|vacation|calendar)s?\s+(in\s+|on\s+)?([a-zA-Z\s]+)\/([a-zA-Z\s]+)()()()\s*\z/i,
           /\A\s*(public\s+)?(holiday?|vacation|calendar)s?\s+(in\s+|on\s+)?([a-zA-Z\s]+)\/([a-zA-Z\s]+)\s+(\d{4})[\/\-]?(\d\d)?[\/\-]?(\d\d)?\s*\z/i,
           /\A\s*(public\s+)?(holiday?|vacation|calendar)s?\s+(in\s+|on\s+)?([a-zA-Z\s]+)()\s+(\d{4})[\/\-]?(\d\d)?[\/\-]?(\d\d)?\s*\z/i
        type = $2.downcase
        country = $4
        state = $5.to_s
        year = $6.to_s
        month = $7.to_s
        day = $8.to_s
        year = Date.today.year if year.to_s == ""
        if type == "calendar"
          save_stats :calendar_country
          state = "/#{state.downcase}" if state.to_s != ""
          display_calendar("", year, country_region: "#{country.downcase}#{state}")
        else
          public_holidays(country, state, year, month, day)
        end

        # help: ----------------------------------------------
        # help: `set public holidays to COUNTRY/STATE`
        # help:     It will set the public holidays for the country and state specified.
        # help:     If STATE is not specified, it will set the public holidays for the country.
        # help: Examples:
        # help:     _set public holidays to Iceland_
        # help:     _set public holidays to United States/California_
        # help: command_id: :set_public_holidays
        # help:
      when /\A\s*set\s+public\s+(holiday?|vacation)s?\s+to\s+([^\/]+)\/([^\/]+)\s*\z/i,
           /\A\s*set\s+public\s+(holiday?|vacation)s?\s+to\s+([^\/]+)\s*\z/i
        country = $2
        state = $3.to_s
        set_public_holidays(country, state, user)

        # help: ----------------------------------------------
        # help: >*<https://github.com/MarioRuiz/slack-smart-bot#personal-settings|PERSONAL SETTINGS>*
        # help: `set personal settings SETTINGS_ID VALUE`
        # help: `delete personal settings SETTINGS_ID`
        # help: `get personal settings SETTINGS_ID`
        # help: `get personal settings`
        # help:     It will set/delete/get the personal settings supplied for the user.
        # help: Examples:
        # help:     _set personal settings ai.open_ai.access_token Xd33-343sAAddd42-3JJkjC0_
        # help: command_id: :set_personal_settings
        # help: command_id: :delete_personal_settings
        # help: command_id: :get_personal_settings
        # help:
      when /\A\s*(set)\s+personal\s+(setting|config)s?\s+([\w\.]+)(\s*=?\s*)(.+)\s*\z/i,
           /\A\s*(delete|get)\s+personal\s+(setting|config)s?\s+([\w\.]+)()()\s*\z/i,
           /\A\s*(get)\s+personal\s+(setting|config)s?()()()\s*\z/i
        settings_type = $1.downcase.to_sym
        settings_id = $3.downcase
        settings_value = $5.to_s
        personal_settings(user, settings_type, settings_id, settings_value)

        # help: ----------------------------------------------
        # help: >*<https://github.com/MarioRuiz/slack-smart-bot#openai|OpenAI>*
        # help: `?w`
        # help: `?w PROMPT`
        # help:     OpenAI: It will transcribe the audio file attached and performed the PROMPT indicated if supplied.
        # help: Examples:
        # help:     _?w_
        # help:     _?w translate to spanish_
        # help:     _?w what is this about?_
        # help:     _?w translate to english and tell me what is about_
        # help: command_id: :open_ai_whisper
        # help:
      when /\A\s*\?w()\s*\z/im, /\A\s*\?w\s+(.+)\s*\z/im
        message = $1.to_s.downcase
        open_ai_whisper(message, files)

        # help: ----------------------------------------------
        # help: `?m`
        # help: `?m MODEL`
        # help: `chatgpt models`
        # help: `?m chatgpt`
        # help:     OpenAI: It will return the list of models available or the details of the model indicated.
        # help:             If chatgpt models is used, it will return the list of chatgpt models available.
        # help: Examples:
        # help:     _?m_
        # help:     _?m gpt-3.5-turbo_
        # help:    _chatgpt models_
        # help: command_id: :open_ai_models
        # help:
      when /\A\s*\?m()\s*\z/im, /\A\s*\?m\s+(.+)\s*\z/im, /\A\s*(chatgpt)\s+models\s*\z/im
        model = $1.to_s.downcase
        open_ai_models(model)

        # help: ----------------------------------------------
        # help: `??i PROMPT`
        # help: `?i PROMPT`
        # help: `?ir`
        # help: `?iv`
        # help: `?ivNUMBER`
        # help: `?ie PROMPT`
        # help:     OpenAI: i PROMPT -> It will generate an image based on the PROMPT indicated.
        # help:             If ??i is used, it will start from zero the session. If not all the previous prompts from the session will be used to generate the image.
        # help:     OpenAI: ir -> It will generate a new image using the session prompts.
        # help:     OpenAI: iv -> It will generate a variation of the last image generated.
        # help:             ivNUMBER -> It will generate the NUMBER of variations of the last image generated. NUMBER need to be between 1 and 9.
        # help:             If an image attached then it will generate the variations of the attached image.
        # help:     OpenAI: ie PROMPT -> It will edit the attached image with the supplied PROMPT. The supplied image need to be an image with a transparent area.
        # help:             The PROMPT need to explain the final result of the image.
        # help: Examples:
        # help:     _??i man jumping from a red bridge_
        # help:     _?i wearing a red hat and blue shirt_
        # help:     _?ir_
        # help:     _?iv5_
        # help:     _?ie woman eating a blue apple_
        # help: command_id: :open_ai_generate_image
        # help: command_id: :open_ai_variations_image
        # help: command_id: :open_ai_edit_image
        # help:
      when /\A\s*()\?i()\s\s*(.+)\s*\z/im, /\A\s*(\?\?)i()\s\s*(.+)\s*\z/im, /\A\s*()\?i(r)()\s*\z/im,
           /\A\s*()\?i(v)()\s*\z/im, /\A\s*()\?i(v\d+)()\s*\z/im,
           /\A\s*()\?i(e)\s+(.+)\s*\z/im,
           /\A\s*()\?i(e)()\s*\z/im,
           /\A\s*(\?\?)i()()\s*\z/im
        delete_history = $1.to_s != ""
        image_opt = $2.to_s.downcase
        message = $3.to_s
        if image_opt == "" or image_opt == "r"
          open_ai_generate_image(message, delete_history, repeat: image_opt == "r")
        elsif image_opt.match?(/v\d*/i)
          variations = image_opt.match(/v(\d*)/i)[1].to_i
          open_ai_variations_image(message, variations, files)
        elsif image_opt == "e"
          open_ai_edit_image(message, files)
        end

        # help: ----------------------------------------------
        # help: `?? PROMPT`
        # help: `? PROMPT`
        # help: `?? use model MODEL_NAME`
        # help: `chatGPT SESSION_NAME`
        # help: `chatGPT SESSION_NAME "DESCRIPTION"`
        # help: `chatGPT SESSION_NAME >TAG_NAME`
        # help: `chatGPT SESSION_NAME >TAG_NAME "DESCRIPTION"`
        # help: `chatGPT SESSION_NAME MODEL_NAME`
        # help: `chatGPT SESSION_NAME MODEL_NAME >TAG_NAME`
        # help: `chatGPT SESSION_NAME MODEL_NAME "DESCRIPTION"`
        # help: `chatGPT SESSION_NAME MODEL_NAME >TAG_NAME "DESCRIPTION"`
        # help:     OpenAI: Chat GPT will generate a response based on the PROMPT indicated.
        # help:             SESSION_NAME: is the name of the session to use. Only a-Z, 0-9, hyphens, and underscore are allowed.
        # help:             When using 'chatGPT SESSION_NAME' in case the name doesn't exist it will create a new session with the name indicated, if exists it will continue the session.
        # help:             When starting a new session, if you ask SmartBot to answer on a Thread by using !! or ^, then it won't be necessary to send ? before the prompt.
        # help:                In this case, every single message you send will be considered a prompt to be treated.
        # help:                After 30 minutes of inactivity SmartBot will stop listening to the thread. You will need to continue the session after that.
        # help:                If you want to avoid a message to be treated then start it with a hyphen '-'.
        # help:                To add a collaborator when on a thread, you can use directly `add collaborator @USER`
        # help:                To change the model when on a thread, you can use directly `use model MODEL_NAME`
        # help:             If ?? is used, it will start from zero the temporary session. If not all the previous prompts from the session will be used to generate the response.
        # help:             You can share a message and use it as input for the supplied PROMPT.
        # help:             If you include in the prompt !URL then it will download and use the content of the URL as input for the prompt.
        # help:             If the URL is a Google Drive link, it will download the content of the file.
        # help:             If the URL is a PDF, DOCX or text file (txt, json, yaml...) SmartBot will extract the content of the file and use it as input for the prompt.
        # help:             Add static content to your session by using `add static content URL1 URL99`. The content will be downloaded and added to your session only once.
        # help:             Add live content to your session by using `add live content URL1 URL99`. The content will be downloaded and added to your session every time you send a new prompt.
        # help:             Add messages from a channel to your session by using `add history #CHANNEL_NAME`.
        # help:             You can add authorizations on a specific ChatGPT session: `add authorization HOST HEADER VALUE`, for example: `add authorization api.example.com Authorization Bearer 123456`.
        # help:             You can attach any image to the message and it will be used as input for the prompt.
        # help:             If you want to delete the last ChatGPT response and send again last prompt, you can use `resend prompt`.
        # help:             You can set the context of your ChatGPT session: `set context CONTEXT`. Example: `set context You are a funny comedian who tells dad jokes. The output should be in JSON format.`
        # help:             MODEL_NAME can be a substring of the model name, SmartBot will search the model name that contains the substring supplied.
        # help:             When "DESCRIPTION" is used it will be used as a description for the session.
        # help:                If a previous DESCRIPTION for the session exists it will be replaced.
        # help:             When >TAG_NAME is used it will be used as a tag for the session.
        # help:                If a previous TAG_NAME for the session exists it will be replaced.
        # help:                Then you can list sessions by TAG_NAME, for example: `chatGPT sessions >dev`, `chatGPT public sessions >test`
        # help: Examples:
        # help:     _?? How much is two plus two_
        # help:     _? multiply it by pi number_
        # help:     _^chatgpt SpanishTeacher_
        # help:     _!!chatgpt data_analyst gpt-3.5-turbo_
        # help:     _^chatgpt SpanishTeacher "I will teach you Spanish"_
        # help:     _^chatgpt SpanishTeacher gpt-3.5-turbo "I will teach you Spanish"_
        # help:     _^chatgpt SpanishTeacher 32k >dev "I will teach you Spanish"_
        # help:     _^chatgpt data_analyst >science_
        # help: command_id: :open_ai_chat
        # help: command_id: :open_ai_chat_add_collaborator
        # help: command_id: :open_ai_chat_use_model
        # help: command_id: :open_ai_chat_add_live_content
        # help: command_id: :open_ai_chat_add_static_content
        # help: command_id: :open_ai_chat_add_authorization
        # help: command_id: :open_ai_chat_resend_prompt
        # help: command_id: :open_ai_chat_set_context
        # help: command_id: :open_ai_chat_delete_live_content
        # help: command_id: :open_ai_chat_delete_static_content
        # help: command_id: :open_ai_chat_delete_authorization
        # help:

        # help: ----------------------------------------------
        # help: `chatGPT get SESSION_NAME`
        # help: `??g SESSION_NAME`
        # help:     OpenAI: SmartBot will get all the prompts from the ChatGPT session indicated.
        # help: Examples:
        # help:     _chatgpt get SpanishTeacher_
        # help:     _??g SpanishTeacher_
        # help: command_id: :open_ai_chat_get_prompts
        # help:

        # help: ----------------------------------------------
        # help: `chatGPT delete SESSION_NAME`
        # help: `??d SESSION_NAME`
        # help:     OpenAI: SmartBot will delete the ChatGPT session indicated.
        # help: Examples:
        # help:     _chatgpt delete SpanishTeacher_
        # help:     _??d SpanishTeacher_
        # help: command_id: :open_ai_chat_delete_session
        # help:

        # help: ----------------------------------------------
        # help: `chatGPT clean SESSION_NAME`
        # help:     OpenAI: SmartBot will delete all the prompts from the ChatGPT session indicated.
        # help: Examples:
        # help:     _chatgpt clean SpanishTeacher_
        # help: command_id: :open_ai_chat_clean_session
        # help:

        # help: ----------------------------------------------
        # help: `chatGPT share SESSION_NAME`
        # help: `chatGPT share SESSION_NAME #CHANNEL`
        # help: `chatGPT stop sharing SESSION_NAME`
        # help: `chatGPT stop sharing SESSION_NAME #CHANNEL`
        # help:     OpenAI: It will share your ChatGPT session with everyone in your workspace if no channel supplied.
        # help:             If channel supplied it will be shared with that channel.
        # help:             If 'stop sharing' is used it will stop sharing the session.
        # help: Examples:
        # help:     _chatgpt share SpanishTeacher_
        # help:     _chatgpt share SpanishTeacher #sales_
        # help:     _chatgpt stop sharing SpanishTeacher_
        # help:     _chatgpt stop sharing SpanishTeacher #sales_
        # help: command_id: :open_ai_chat_share_session
        # help:

        # help: ----------------------------------------------
        # help: `chatGPT sessions`
        # help: `chatGPT public sessions`
        # help: `chatGPT shared sessions`
        # help: `chatGPT sessions >TAG_NAME`
        # help: `chatGPT public sessions >TAG_NAME`
        # help: `chatGPT shared sessions >TAG_NAME`
        # help: `??l`
        # help:     OpenAI: SmartBot will list the ChatGPT sessions.
        # help:             'sessions' will list the sessions you have created.
        # help:             If 'public sessions' is used it will list the public sessions.
        # help:             If 'shared sessions' is used it will list the shared sessions on the channel.
        # help:             If TAG_NAME is supplied it will list the sessions with that tag.
        # help: Examples:
        # help:     _chatgpt sessions_
        # help:     _chatgpt public sessions_
        # help:     _chatgpt shared sessions >testing_
        # help:     _chatgpt sessions >dev_
        # help: command_id: :open_ai_chat_list_sessions
        # help:

        # help: ----------------------------------------------
        # help: `chatGPT copy SESSION_NAME`
        # help: `chatGPT copy SESSION_NAME NEW_SESSION_NAME`
        # help: `chatGPT copy temporary session NEW_SESSION_NAME`
        # help: `chatGPT use USER_NAME SESSION_NAME`
        # help: `chatGPT use USER_NAME SESSION_NAME NEW_SESSION_NAME`
        # help: `?? use SESSION_NAME`
        # help: `?? use SESSION_NAME NEW_PROMPT`
        # help: `?? use USER_NAME SESSION_NAME`
        # help: `?? use USER_NAME SESSION_NAME NEW_PROMPT`
        # help:     OpenAI: SmartBot will copy the ChatGPT session indicated.
        # help:             If NEW_SESSION_NAME is supplied it will be used as the name for the new session.
        # help:             If USER_NAME is supplied it will copy the session from that user on shared sessions.
        # help:             In case no NEW_SESSION_NAME is supplied it will use the same name as the original session plus a number.
        # help:             If ?? is used it will start a new temporary session with the prompts from the session indicated.
        # help: Examples:
        # help:     _chatgpt copy SpanishTeacher_
        # help:     _chatgpt copy SpanishTeacher spanish_lessons_
        # help:     _chatgpt use peterw SpanishTeacher_
        # help:     _chatgpt use susanssd dataAnalysis DataSales_
        # help:     _?? use peterw SpanishTeacher_
        # help:     _?? use stats_sales can you project the sales for next month?_
        # help:     _?? use susanssd dataAnalysis How much is the total?_
        # help: command_id: :open_ai_chat_copy_session
        # help: command_id: :open_ai_chat_copy_session_from_user
        # help:

        #chatgpt get
      when /\A\s*\?\?(g)\s+([\w\-0-9]+)()\s*\z/im,
           /\A\s*chatgpt\s+(get)\s+([\w\-0-9]+)()\s*\z/im
        session_name = $2.to_s
        open_ai_chat_get_prompts(session_name)

        #chatgpt delete
      when /\A\s*\?\?(d)\s+([\w\-0-9]+)()\s*\z/im,
           /\A\s*chatgpt\s+(delete)\s+([\w\-0-9]+)()\s*\z/im
        session_name = $2.to_s
        open_ai_chat_delete_session(session_name)

        #chatgpt share
      when /\A\s*chatgpt\s+(share)\s+([\w\-0-9]+)\s+(on\s+|in\s+)?<#(\w+)\|.*>\s*\z/im,
           /\A\s*chatgpt\s+(share)\s+([\w\-0-9]+)()()\s*\z/im,
           /\A\s*chatgpt\s+(stop)\s+sharing\s+([\w\-0-9]+)\s+(on\s+|in\s+)?<#(\w+)\|.*>\s*\z/im,
           /\A\s*chatgpt\s+(stop)\s+sharing\s+([\w\-0-9]+)()()\s*\z/im
        type = $1.to_s.downcase.to_sym
        session_name = $2.to_s
        channel_id = $4.to_s
        open_ai_chat_share_session(type, session_name, channel_id)

        #chatgpt list
      when /\A\s*chatgpt\s+(list\s+)?sessions()()\s*\z/im,
           /\A\s*chatgpt\s+(list\s+)?sessions()\s+>([\w\-0-9]+)\s*\z/im,
           /\A\s*chatgpt\s+(list\s+)?()>([\w\-0-9]+)\s+sessions\s*\z/im,
           /\A\s*chatgpt\s+(list\s+)?(public)\s+sessions()\s*\z/im,
           /\A\s*chatgpt\s+(list\s+)?(public)\s+sessions\s+>([\w\-0-9]+)\s*\z/im,
           /\A\s*chatgpt\s+(list\s+)?(public)\s+>([\w\-0-9]+)\s+sessions\s*\z/im,
           /\A\s*chatgpt\s+(list\s+)?(shared)\s+sessions()\s*\z/im,
           /\A\s*chatgpt\s+(list\s+)?(shared)\s+sessions\s+>([\w\-0-9]+)\s*\z/im,
           /\A\s*chatgpt\s+(list\s+)?(shared)\s+>([\w\-0-9]+)\s+sessions\s*\z/im,
           /\A\s*\?\?l\s*\z()()/im,
           /\A\s*\?\?l\s*\z()\s+>([\w\-0-9]+)/im
        type = $2.to_s.downcase.to_sym
        tag = $3.to_s.downcase
        type = :own if type.to_s == ""
        open_ai_chat_list_sessions(type, tag: tag)

        #chatgpt copy
      when /\A\s*chatgpt\s+copy\s+temporary\s+session\s+()([\w\-0-9]+)\s*\z/im,
           /\A\s*chatgpt\s+copy\s+([\w\-0-9]+)()\s*\z/im,
           /\A\s*chatgpt\s+copy\s+([\w\-0-9]+)\s+([\w\-0-9]+)\s*\z/im
        session_name = $1.to_s
        new_session_name = $2.to_s
        open_ai_chat_copy_session("", "", session_name, new_session_name)

        #chatgpt use session
      when /\A\s*chatgpt\s+use\s+([\w\-0-9]+)\s+([\w\-0-9]+)()\s*\z/im,
           /\A\s*chatgpt\s+use\s+([\w\-0-9]+)\s+([\w\-0-9]+)\s+([\w\-0-9]+)\s*\z/im
        user_name = $1.to_s
        session_name = $2.to_s
        new_session_name = $3.to_s
        #if user_name include the team_id + "_" in the begining then assign to user_team_id and remove it from user_name
        if user_name.match?(/\A[A-Z0-9]{7,11}_/)
          user_team_id = user_name.match(/\A([A-Z0-9]{7,11})_/)[1]
          user_name = user_name.gsub(/\A[A-Z0-9]{7,11}_/, "")
        else
          user_team_id = ""
        end
        open_ai_chat_copy_session(user_team_id, user_name, session_name, new_session_name)

        #?? use model
      when /\A\s*(\?\?)()\s+use\s+model\s+([\w\-0-9\.]+)()()\s*\z/im,
           /\A\s*\?\s+(use)\s+model\s+()([\w\-0-9\.]+)()()\s*\z/im
        model = $3.to_s
        if $1.to_s == "??"
          open_ai_chat("", true, :temporary, model: model)
        else
          open_ai_chat_use_model(model)
        end

        #chatgpt use session for temporary session
      when /\A\s*\?\?\s*use\s+(session\s+)?([\w\-0-9]+)()()\s*\z/im, #use SESSION_NAME
           /\A\s*\?\?\s*use\s+(session\s+)?([\w\-0-9]+)\s+([\w\-0-9]+)()\s*\z/im, #use USER_NAME SESSION_NAME
           /\A\s*\?\?\s*use\s+(session\s+)?([\w\-0-9]+)\s+([\w\-0-9]+)\s+(.+)\s*\z/im, #use USER_NAME SESSION_NAME NEW_PROMPT
           /\A\s*\?\?\s*use\s+(session\s+)?([\w\-0-9]+)\s+(.+)()\s*\z/im #use SESSION_NAME NEW_PROMPT
        user_name = $2.to_s
        session_name = $3.to_s
        new_prompt = $4.to_s
        session_found = false
        more_than_one = false

        if !@open_ai.keys.any? { |team_id_user| team_id_user.match?(/\A[A-Z0-9]{7,11}_#{user_name}$/) }
          session_name += " " + new_prompt
          new_prompt = ""
        end
        short_command = false
        if new_prompt == "" #use SESSION_NAME or use SESSION_NAME PROMPT
          short_command = true
          get_openai_sessions()
          new_prompt = session_name
          session_name = user_name
          @open_ai.keys.each do |team_id_user|
            if @open_ai[team_id_user][:chat_gpt].key?(:sessions) and
               @open_ai[team_id_user][:chat_gpt][:sessions].key?(session_name)
              if @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:shared].size > 0
                members_shared = []
                @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:shared].each do |shared|
                  members_shared += get_channel_members(shared)
                end
                members_shared.uniq!
              else
                members_shared = []
              end

              if team_id_user == user.team_id_user or
                 @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:public] or
                 @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:shared].include?(dest) or
                 members_shared.include?(user.id)
                user_name = @open_ai[team_id_user][:chat_gpt][:sessions][session_name][:user_creator]
                more_than_one = true if session_found
                session_found = true
              end
              break if more_than_one
            end
          end
        end
        if more_than_one
          respond "There is more than one session with that name. Please specify the user name."
          save_stats(:open_ai_chat_copy_session_from_user)
        elsif !session_found and short_command
          respond ":exclamation: Session not found.\nCall `chatGPT sessions` to see the list of your sessions\n`chatGPT public sessions` to see the public sessions.\n`chatGPT shared sessions` to see the shared sessions."
        else
          success = open_ai_chat_copy_session("", user_name, session_name, "", temporary_session: true)
          open_ai_chat(new_prompt, false, :temporary) if new_prompt != "" and success
        end

        # chatgpt chat
      when /\A\s*\?\s+(add\s+collaborator)\s+<@(\w+)>()()()\s*\z/im,
           /\A\s*\?\?(s|c)\s+([\w\-0-9]+)()()()\s*\z/im,
           /\A\s*chatgpt\s+(start|continue|load|clean)\s+([\w\-0-9]+)()()()\s*\z/im,
           /\A\s*(chatgpt)\s+([\w\-0-9]+)()()()\s*\z/im, #chatgpt session_name
           /\A\s*(chatgpt)\s+([\w\-0-9]+)()\s+>([\w\-0-9]+)()\s*\z/im, #chatgpt session_name >tag_name
           /\A\s*(chatgpt)\s+([\w\-0-9]+)\s+([\w\-0-9\.]+)()()\s*\z/im, #chatgpt session_name model_name
           /\A\s*(chatgpt)\s+([\w\-0-9]+)\s+([\w\-0-9\.]+)\s+>([\w\-0-9\.]+)()\s*\z/im, #chatgpt session_name model_name >tag_name
           /\A\s*(chatgpt)\s+([\w\-0-9]+)()\s+>([\w\-0-9]+)\s+(".+")\s*\z/im, #chatgpt session_name >tag_name "description"
           /\A\s*(chatgpt)\s+([\w\-0-9]+)()()\s+(".+")\s*\z/im, #chatgpt session_name "description"
           /\A\s*(chatgpt)\s+([\w\-0-9]+)\s+([\w\-0-9\.]+)()\s+(".+")\s*\z/im, #chatgpt session_name model_name "description"
           /\A\s*(chatgpt)\s+([\w\-0-9]+)\s+([\w\-0-9\.]+)\s+>([\w\-0-9]+)\s+(".+")\s*\z/im, #chatgpt session_name model_name >tag_name "description"
           /\A\s*(\?\?)\s*()()()()\z/im, /\A\s*(\?\?)\s*(.+)()\s*()()\z/im, /\A\s*()(\?\s*.+)()\s*()()\z/im
        type = $1.to_s.downcase
        text = $2.to_s
        model = $3.to_s
        tag = $4.to_s
        description = $5.to_s
        delete_history = type == "??"
        type.strip!
        if type == "s" or type == "start" or type == "chatgpt"
          type = :start
        elsif type == "c" or type == "continue" or type == "load"
          type = :continue
        elsif type == "clean"
          type = :clean
          delete_history = true
        elsif type.match?(/add\s+collaborator/)
          type = :add_collaborator
        else
          if text.match?(/\A\?[^\?]/im) and !text.match?(/\A\?\s+\?\?/im)
            type = :continue_session
            #remove first ? from the prompt
            text = text[1..-1]
          else
            type = :temporary
            if text == "??" or text.match?(/\A\?\s+\?\?/)
              delete_history = true
              text = ""
            end
          end
        end
        if type == :add_collaborator
          open_ai_chat_add_collaborator(text)
        else
          open_ai_chat(text, delete_history, type, model: model, tag: tag, description: description, files: files)
        end

        # help: ----------------------------------------------
        # help: >*<https://github.com/MarioRuiz/slack-smart-bot#recap|RECAP>*
        # help: `recap`
        # help: `my recap`
        # help: `recap from YYYY/MM/DD`
        # help: `recap from YYYY/MM/DD to YYYY/MM/DD`
        # help: `recap YYYY`
        # help: `recap #CHANNEL`
        # help: `my recap #CHANNEL`
        # help: `recap from YYYY/MM/DD #CHANNEL`
        # help: `recap from YYYY/MM/DD to YYYY/MM/DD #CHANNEL`
        # help: `recap YYYY #CHANNEL`
        # help:     It will show a recap of the channel. If channel not supplied, it will show the recap of the current channel
        # help:     If 'my' is added, it will show also a recap of your messages
        # help:     If only one date is added, it will show the recap from that day to 31st of December of that year
        # help:     If only one year is added, it will show the recap from 1st of January to 31st of December of that year
        # help:  Examples:
        # help:     _recap_
        # help:     _my recap_
        # help:     _recap 2022_
        # help:     _my recap from 2023/07/01 to 2023/12/31_
        # help:     _recap from 2023/07/01 to 2023/12/31 #sales_
        # help:     _my recap from 2023/07/01 #sales_
        # help:     _recap 2023 #sales_
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#recap|more info>
        # help: command_id: :recap
        # help:
      when /\A\s*(my\s+)?recap\s*()(\d\d\d\d)?()()()\z/i, /\A\s*(my\s+)?recap\s*()(\d\d\d\d)?()()\s*<#(\w+)\|?.*>\z/i,
           /\A\s*(my\s+)?recap\s*(from\s+)?(\d\d\d\d[\.\-\/]\d\d[\.\-\/]\d\d)\s*(to\s+)?(\d\d\d\d[\.\-\/]\d\d[\.\-\/]\d\d)?()\z/i,
           /\A\s*(my\s+)?recap\s*(from\s+)?(\d\d\d\d[\.\-\/]\d\d[\.\-\/]\d\d)\s*(to\s+)?(\d\d\d\d[\.\-\/]\d\d[\.\-\/]\d\d)?\s*<#(\w+)\|?.*>\z/i
        my_recap = $1.to_s != ""
        date_start = $3.to_s
        date_end = $5.to_s
        channel = $6.to_s
        channel = dest if channel == ""
        recap(user, dest, channel, date_start, date_end, my_recap)

        # help: ----------------------------------------------
        # help: >*<https://github.com/MarioRuiz/slack-smart-bot#summarize|SUMMARIZE>*
        # help: `summarize`
        # help: `summarize since YYYY/MM/DD`
        # help: `summarize #CHANNEL`
        # help: `summarize #CHANNEL since YYYY/MM/DD`
        # help: `summarize URL_THREAD`
        # help:     It will summarize using ChatGPT the messages in the channel since the date specified.
        # help:     If no date is specified it will summarize the last 30 days.
        # help:     If time off added using Time Off command it will summarize since your last time off date started.
        # help:     If no channel is specified it will summarize the current channel.
        # help:     If a thread URL is specified it will summarize the thread.
        # help:     If the command is used in a thread it will summarize the thread.
        # help: Examples:
        # help:    _summarize_
        # help:    _summarize since 2024/01/22_
        # help:    _summarize #sales_
        # help:    _summarize #sales since 2024/01/22_
        # help:    _summarize https://yourcompany.slack.com/archives/C111JG4V4DZ/p1622549264010700 _
        # help:    <https://github.com/MarioRuiz/slack-smart-bot#summarize|more info>
        # help:  command_id: :summarize
        # help:
      when /\A\s*summarize()()()\s*\z/i, /\A\s*summarize\s+<#\w+\|(.+)>()()\s*\z/i, /\A\s*summarize\s+<#(\w+)\|>\s*()()\z/i,
           /\A\s*summarize()\s+since\s+(\d{4}[-\/]\d{2}[-\/]\d{2})()\s*\z/i, /\A\s*summarize\s+<#\w+\|(.+)>\s+since\s+(\d{4}[-\/]\d{2}[-\/]\d{2})()\s*\z/i,
           /\A\s*summarize\s+<#(.+)\|>\s+since\s+(\d{4}[-\/]\d{2}[-\/]\d{2})()\s*\z/i,
           /\A\s*summarize\s+https:\/\/\w+\.slack\.com\/archives\/(\w+)()\/p(\d+)\s*\z/i,
           /\A\s*summarize\s+https:\/\/\w+\.slack\.com\/archives\/(\w+)()\/(\d+\.\d+)\s*\z/i
        channel = $1.to_s
        from = $2.to_s
        thread_ts = $3.to_s
        channel = dest if channel == ""
        summarize(user, dest, channel, from, thread_ts)

        # help: >*<|OTHER GENERAL COMMANDS>*

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
end
