# Slack Smart Bot

[![Gem Version](https://badge.fury.io/rb/slack-smart-bot.svg)](https://rubygems.org/gems/slack-smart-bot)
[![Build Status](https://travis-ci.com/MarioRuiz/slack-smart-bot.svg?branch=master)](https://github.com/MarioRuiz/slack-smart-bot)
[![Coverage Status](https://coveralls.io/repos/github/MarioRuiz/slack-smart-bot/badge.svg?branch=master)](https://coveralls.io/github/MarioRuiz/slack-smart-bot?branch=master)
![Gem](https://img.shields.io/gem/dt/slack-smart-bot)
![GitHub commit activity](https://img.shields.io/github/commit-activity/y/MarioRuiz/slack-smart-bot)
![GitHub last commit](https://img.shields.io/github/last-commit/MarioRuiz/slack-smart-bot)
![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/MarioRuiz/slack-smart-bot)

Create a highly smart Slack bot that is incredibly easy to customize and expand.

The primary purpose of this Ruby gem is to be used internally within your company, allowing teams to create dedicated channels with their own bot to assist them with their daily tasks. Almost any task can be automated with ease!

slack-smart-bot has the ability to create bots on demand, set up shortcuts, execute Ruby code, utilize ChatGPT, DALL-E, Whisper, and more. All of this can be done directly within a chat channel, even from your mobile phone. Whether you need to run forgotten tests, retrieve results, restart a server, summarize a channel or just a thread, or engage in a ChatGPT session, the possibilities are limitless.

<img src="img/smart-bot-150.png"><img src="img/slack-300.png"><img src="img/openai-300.png">  

# Table of Contents
(A): Only for Admins  

- [Installation and configuration](#installation-and-configuration) (A)
- [Usage](#usage)
  * [creating the MASTER BOT](#creating-the-master-bot) (A)
  * [How to access the Smart Bot](#how-to-access-the-smart-bot)
  * [Bot Help](#bot-help)
  * [Bot Management](#bot-management) (A)
    + [Cloud Bots](#cloud-bots) (A)
  * [Extending rules to other channels](#extending-rules-to-other-channels) (A)
  * [Using rules from other channels](#using-rules-from-other-channels)
  * [Running Ruby code on a conversation](#running-ruby-code-on-a-conversation)
    + [REPL](#repl)
  * [Sending notifications](#sending-notifications) (A)
  * [Shortcuts](#shortcuts)
  * [Announcements](#announcements)
  * [Share Messages](#share-messages)
  * [See Statuses](#see-statuses)
  * [Routines](#routines) (A)
  * [Loops](#loops)
  * [Control who has access to a command](#control-who-has-access-to-a-command) (A)
  * [See favorite commands](#see-favorite-commands)
  * [Teams](#teams)
  * [Time off management](#time-off-management)
  * [OpenAI](#openai)
    + [OpenAI Set up](#openai-setup) (A)
    + [Chat GPT](#chatgpt)
      + [Docs Folder for ChatGPT Sessions](#docs-folder-for-chatgpt-sessions) (A)
      + [Restrict who has access to a specific model](#restrict-who-has-access-to-a-specific-model) (A)
    + [Image Generation](#image-generation)
    + [Image Variations](#image-variations)
    + [Image Editing](#image-editing)
    + [Whisper](#whisper)
    + [Models](#models)
  * [Recap](#recap)
  * [Summarize](#summarize)
  * [Personal Settings](#personal-settings)
  * [Tips](#tips)
    + [Send a file](#send-a-file) (A)
    + [Download a file](#download-a-file) (A)
- [Contributing](#contributing)
- [License](#license)

## Installation and configuration
> for admins

    $ gem install slack-smart-bot
    
After you install it you will need just a couple of things to configure it.

Create a file like this on the folder you want:

```ruby

require 'slack-smart-bot'

settings = {
    # the channel that will act like the master channel, main channel
    master_channel: 'my_master_channel',
    masters: ["mario"], #names of the master users
    token: 'xxxxxxxxxxxxxxxxxx', # the API Slack token
    user_token: 'yyyyyyyyyy', # The API Slack User token
    granular_token: 'zzzzzzzz' # The API Granular Slack Token
}

puts "Connecting #{settings.inspect}"
SlackSmartBot.new(settings).listen

```

The master_channel will be the channel where you will be able to create other bots and will have special treatment.

The masters will have full access to everything. You need to use the slack user name defined on https://YOUR_WORK_SPACE.slack.com/account/settings#username.

Create the SmartBot *[Slack App. Bot Token](https://api.slack.com/slack-apps)* :

  1) [Create a Classic Slack App](https://api.slack.com/apps?new_classic_app=1) This will be our *@smart-bot App* we will interact with. This App will use RTM to connect to Slack.    

  1) Add a bot user to your app. On Add features and functionality section for your app, select *Bots*. Click on *Add a Legacy Bot User*

  1) On your app click on the menu on the left: *OAuth & Permissions*. Add the 'users.profile:write' scope. This is necessary for the SmartBot to be able to change the slack status of other users.  
  
  1) Now you will need to ask a workspace admin to click on *Install App to Workspace*.

  1) Copy your *Bot User OAuth Access Token* and add it to the SmartBot settings with key :token

  1) Ask a workspace admin to provide the *User OAuth Token* and add it to the SmartBot settings with key :user_token  

Now we will create the GranularSmartBot Slack App to get access to certain end points as a regular Slack App:  

  1) [Create a Granular Slack App](https://api.slack.com/apps?new_app=1) This will be our @granular-smart-bot App. It will be used internally on the SmartBot. It is a regular Slack App with scopes.  

  1) On your app click on the menu on the left: *OAuth & Permissions* and add on Bot Token Scopes the necessary Scopes: app_mentions:read, channels:history, channels:read, chat:write, chat:write.customize, emoji:read, files:read, groups:history, groups:read, im:history, im:read, im:write, incoming-webhook, mpim:history, mpim:read, mpim:write, reactions:read, reactions:write, team:read, users.profile:read, users:read, users:read.email  
  
  1) Click on *Install App to Workspace*.  

  1) Copy the *Bot User OAuth Token* and add it to the SmartBot settings with the key :granular_token  

Both Apps need to be on the channels we want to use the SmartBot.  

*Remember to invite the smart bot to the channels where they will be accessible before starting the bot*  

SmartBot will notify about SmartBot status changes or any SmartBot incident if defined the status_channel in settings file and the channel exists. By default: smartbot-status  


This is an example of typical settings to be supplied for the *Slack Smart Bot* instance:
```ruby
settings = {
  token: ENV["SLACK_BOT_TOKEN"],
  user_token: ENV['SLACK_USER_TOKEN'],
  granular_token: ENV['SLACK_GRANULAR_BOT_TOKEN'],
  masters: ["mario", "peterv", "lisawhite"], #master admin users
  master_channel: "smartbot_master",
  silent: true,
  stats: true,
  encrypt: true,
  encryption: { # if not encryption key supplied then it will be generated one using the host name and the Slack token
    key: ENV['ENCRYPTION_KEY'], 
    iv: ENV['ENCRYPTION_IV']
  },
  github: {
    token: ENV['GITHUB_TOKEN']
  },
  jira: {
    host: ENV['JIRA_HOST'], 
    user: ENV['JIRA_USER'], 
    password: ENV['JIRA_PASSWORD']
  },
  public_holidays: {
    api_key: ENV['CALENDARIFIC_API_KEY'],
    default_calendar: 'spain/madrid'
  },
  ai: {
    open_ai: {
      access_token: ENV["OPENAI_ACCESS_TOKEN"],
      chat_gpt: {
        model: 'gpt-3.5-turbo-0613', # to be used by default for the user calling chatgpt command
        smartbot_model: 'gpt-4-32k-0613' # to be used by default by the SmartBot internally
      }
    }
  }
}

```

You can see all the accepted settings on: [/lib/slack/smart-bot/config.rb](/lib/slack/smart-bot/config.rb)  

To use the other integrated services:
* OpenAI: https://platform.openai.com/account/api-keys
* Calendarific: https://www.calendarific.com 
* GitHub: https://github.com/settings/tokens
* Jira: https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/



## Usage

### creating the MASTER BOT
> for admins

Let's guess the file you created was called my_smart_bot.rb so, just run it:
```
nohup ruby my_smart_bot.rb&
```
nohup will prevent the terminal to send the signal exception: SIGHUP and kill the bot. & will run the process in background. You can use instead: **_`ruby my_smart_bot.rb & disown`_**

After the run, it will be generated a rules file with the same name but adding _rules, in this example: my_smart_bot_rules.rb

The rules file can be edited and will be only affecting this particular bot.

You can add all the rules you want for your bot in the rules file, this is an example:

```ruby
def rules(user, command, processed, dest)
  from = user.name
  display_name = user.profile.display_name

  case command

    # help: `echo SOMETHING`
    # help:     repeats SOMETHING
    # help:
    when /^echo\s(.+)/i
      respond $1
      react :monkey_face

    # help: `go to sleep`
    # help:   it will sleep the bot for 10 seconds
    # help:
    when /^go\sto\ssleep/i
      if answer.empty?
        ask "do you want me to take a siesta?"
      else
        case answer
          when /yes/i, /yep/i, /sure/i
            answer_delete
            respond "I'll be sleeping for 10 secs... just for you"
            respond "zZzzzzzZZZZZZzzzzzzz!"
            react :sleeping
            sleep 10
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
    # help:
    when /^run something/i
      react :runner

      process_to_run = "ruby -v"
      stdout, stderr, status = Open3.capture3(process_to_run)
      if stderr == ""
        if stdout == ""
          respond "#{user.name}: Nothing returned."
        else
          respond "#{user.name}: #{stdout}"
        end
      else
        respond "#{user.name}: #{stdout} #{stderr}"
      end
      
      unreact :runner

    # Example sending blocks. More info: https://api.slack.com/block-kit
    # help: It will return the info about who is the admin
    when /\AWho is the admin\?\z/i
         my_blocks = [
           { type: "context",
             elements:
               [
                 { type: "plain_text", :text=>"\tAdmin: " },
                 { type: "image", image_url: "https://avatars.slack-edge.com/2021-03-23/182815_e54abb1dd_24.jpg", alt_text: "mario" },
                 { type: "mrkdwn", text: " *Mario Ruiz* (marior)  " }
               ]
           }
         ]
         respond blocks: my_blocks

    else
      unless processed
        dont_understand()
      end
  end
end
```

Also you can add general rules that will be available on all Smart Bot channels to `./rules/general_rules.rb`

If you have commands that want to make them available everywhere the Smart Bot is a member then add those commands to `./rules/general_commands.rb`. 

### How to access the Smart Bot
> for all users

You can access the bot directly on the MASTER CHANNEL, on a secondary channel where the bot is running and directly by opening a private chat with the bot, in this case the conversation will be just between you and the bot.

On a Smart Bot channel you will be able to run some of the commands just by writing a command, for example: **_`bot help`_**

Some commands will be only available when the Smart Bot is listening to you. For the Smart Bot to start listening to you just say: **_`hi bot`_**. When the Smart Bot is listening to you, you can skip a message to be treated by the bot by starting the message with '-', for example: **_`-this message won't be treated`_**. When you want the Smart Bot Stop listening to you: **_`bye bot`_**. The Smart Bot will automatically stop listening to you after 30 minutes of inactivity. If you are on a direct conversation with the Smart Bot then it will be on *listening* mode all the time.

All the specific commands of the bot are specified on your rules file and can be added or changed accordingly. We usually call those commands: *rules*. Those rules are only available when the bot is listening to you.

Another way to run a command/rule is by asking *on demand*. In this case it is not necessary that the bot is listening to you.

To run a command on demand:  
  **_`!THE_COMMAND`_**  
  **_`@NAME_OF_BOT THE_COMMAND`_**  
  **_`NAME_OF_BOT THE_COMMAND`_**  
To run a command on demand and add the response on a thread:  
  **_`^THE_COMMAND`_**  
  **_`!!THE_COMMAND`_**

Examples run a command on demand:  

<img src="img/commands_on_demand.png" width="500">  


Also you can always call the Smart Bot from any channel, even from channels without a running Smart Bot. You can use the External Call on Demand: **_`@NAME_OF_BOT on #CHANNEL_NAME COMMAND`_**. In this case you will call the bot on #CHANNEL_NAME. You can supply more than one channel then all the bots will respond. In case you are in a private conversation with the Smart Bot (DM) then you can use directly:  **_`#CHANNEL_NAME COMMAND`_** or **_`on #CHANNEL_NAME COMMAND`_**

Examples:  

<img src="img/commands_on_external_call.png" width="400">  

Examples on DM:
>**_Peter>_** `#sales show report from India`  
>**_Peter>_** `on #sales notify clients`

If you want the Smart Bot just listen to part of the message you send, add the commands you want using '`' and start the line with '-!', '-!!' or '-^'

Examples:  
<img src="img/commands_inline.png" width="500">  


All the commands specified on `./rules/general_commands.rb` will be accessible from any channel where the Smart Bot is present, without the necessity to call it with !, !!, ^ or on demand.

Examples:
>**_Peter>_** `Thanks smartbot`  
>**_Smart-Bot>_** `You're very welcome`  

### Bot Help
> for all users

To get a full list of all commands and rules for a specific Smart Bot: **_`bot help`_**. It will show only the specific available commands for the user requesting. By default it will display only a short version of the bot help, call **_`bot help expanded`_** to get a expanded version of all commands.

If you want to search just for a specific command: **_`bot help COMMAND`_** It will display expanded explanations for the command.

To show only the specific rules of the Smart Bot defined on the rules file: **_`bot rules`_** or **_`bot rules COMMAND`_**

Also you can call `suggest command` or `random command` and SmartBot will return the help content for a random command.

Example:  
<img src="img/command_bot_help_echo.png" width="250">  


When you call a command that is not recognized, you will get suggestions from the Smart Bot.

Remember when you add code to your rules you need to specify the help that will be displayed when using `bot help`, `bot rules`

For the examples use _ and for the rules `. This is a good example of a Help supplied on rules source code:

```ruby
# help: ----------------------------------------------
# help: `run TYPE tests on LOCATION`
# help: `execute TYPE tests on LOCATION`
# help:     run the specified tests on the indicated location
# help:       TYPE: api, ui, smoke, load
# help:       LOCATION: customers, db1..db10, global
# help:  Examples:
# help:     _run api tests on customers_
# help:     _run ui tests on customers_
# help:     _execute smoke tests on db1_
```

To see what's new just call `What's new`. And to get the SmartBot README call `get smartbot readme`.  

### Bot Management
> for admins

To create a new bot on a channel, run on MASTER CHANNEL: **_`create bot on CHANNEL`_**. The admins of this new bot on that channel will be the MASTER ADMINS, the creator of the bot and the creator of that channel. It will create a new rules file linked to this new bot.

You can kill any bot running on any channel if you are an admin of that bot: **_`kill bot on CHANNEL`_**

If you want to pause a bot, from the channel of the bot: **_`pause bot`_**. To start it again: **_`start bot`_**

To see the status of the bots, on the MASTER CHANNEL: **_`bot status`_**

If you need it you can set the SmartBot on maintenance mode by running: **_`set maintenance on`_**. A message to be displayed can be added if not the default message will be used. Run **_`set maintenance off`_** when you want the SmartBot to be running in normal conditions again.

To display a general message after every command use: `set general message MESSAGE`. Use `set general message off` to stop displaying it.

To close the Master Bot, run on MASTER CHANNEL: **_`exit bot`_**

If you are a Master Admin on a Direct Message with the Smart Bot you can call the **_`bot stats`_** and get use stats of the users. You need to set to `true` the `stats` settings when initializing the Smart Bot. As a normal user you will get your own stats when calling **_`bot stats`_**. Take a look at `bot help bot stats` for more info. If you are a member of #smartbot-stats you can use the bot stats command on that channel. You can set a different channel by supplying it on the config key stats_channel. Also you can call **_`leaderboard`_** to get some useful information about the use of the SmartBot.

You can also get the bot logs of the bot channel you are using by calling `get bot logs`. You need to be a Master Admin user on a DM with the Smart Bot.

You can add, remove and list admins of any channel by using: `add admin @user`, `remove admin @user` and `see admins`. You need to be the creator of the channel, a Master admin or an admin.

To see the full list of available command ids on any channel call: `see command ids`

#### Cloud Bots
> for admins

If you want to create a bot that will be running on a different machine: **_`create cloud bot on CHANNEL`_**. Even though the cloud bots are running on different machines, the management can be done through the MASTER CHANNEL. The new cloud bot will be managed by your Master Bot like the others, closing, pausing...

Cloud Bots are typically used to run commands on specific environments or even different OS or networks.

### Extending rules to other channels
> for admins

If you want to extend the use of your specific rules on a Bot Channel to a third channel you can use the command: **_`extend rules to CHANNEL`_**

From that moment everybody part of that channel will be able to run the specific rules from the other channel but just on demand, for example: **_`!run something`_**

To stop allowing it: **_`stop using rules on CHANNEL`_**

### Using rules from other channels
> for all users

To be able to access the rules from other channel or from a direct conversation with the bot, first of all you need to be a member of that channel. Then on a direct conversation with the Smart Bot or from another bot channel: **_`use rules from CHANNEL`_**

When you want to stop using those rules with the bot: **_`stop using rules from CHANNEL`_**

Also you can always call the Smart Bot from any channel, even from channels without a running Smart Bot. You can use the External Call on Demand: **_`@NAME_OF_BOT on #CHANNEL_NAME COMMAND`_**. In this case you will call the bot on #CHANNEL_NAME.

### Running Ruby code on a conversation
> for all users

You can run Ruby code by using the command: **_`ruby THE_CODE`_**. 

Example:  
<img src="img/command_ruby.png" width="650">  


Also it is possible to attach a Ruby file and the Smart Bot will run and post the output. You need to select Ruby as file format. Or if you prefer it you can call the `ruby` command and on the same message supply a code block.

#### REPL
> for all users

For a quick introduction play this video:  
[![SmartBot REPLs](https://img.youtube.com/vi/URMI3BdD7J8/0.jpg)](https://www.youtube.com/watch?v=URMI3BdD7J8)  

Easily starts a REPL session so you will be able to create a script directly from the slack conversation. You will be able to share the REPL so they can run it or see the content.

It Will run all we write as a ruby command and will keep the session values until we finish the session sending `quit`, `exit` or `bye` 

You can specify a SESSION_NAME that admits from a to Z, numbers, - and _. If no SESSION_NAME supplied it will be treated as a temporary REPL.
If 'private' specified in the command the REPL will be accessible only by you and it will be displayed only to you when `see repls`

To avoid a message to be treated when a session started, start the message with '-'.

Send puts, print, p or pp if you want to print out something when using `run repl` later.

If you declare on your rules file a method called `project_folder` returning the path for the project folder, the code will be executed from that folder. 

By default it will be automatically loaded the gems: `string_pattern`, `nice_hash` and `nice_http`

To pre-execute some ruby when starting the session add the code to `.smart-bot-repl` file on the project root folder defined on `project_folder`. Then that file will be always executed before the REPL started or created. In that case if we want to avoid to run that file before the REPL we can do it adding the word 'clean' before the command `clean repl`.

If you want to see the methods of a class or module you created use `ls TheModuleOrClass`. To see all documentation of a method: `doc TheModuleOrClass.method_name`. And to see the source code of a method: `code TheModuleOrClass.method_name`. Examples: `ls Sales`, `doc Sales.list`, `code Sales.list`  

During the REPL session you can ask *ChatGPT* about the code or any other question. Just start the message with `?` and the Smart Bot will ask ChatGPT and will post the answer. Example: `? How to create a new customer?`. If you send just the question mark without a prompt then ChatGPT will suggest next code line. Example: `?`  

You can supply the Environmental Variables you need for the Session  

Examples:  
  _repl CreateCustomer LOCATION=spain HOST='https://10.30.40.50:8887'_  
  _repl CreateCustomer: "It creates a random customer for testing" LOCATION=spain HOST='https://10.30.40.50:8887'_  
  _repl delete\_logs_  
  _private repl random-ssn_  
  _repl_


Running Example:  
<img src="img/command_repl1.png" width="650">  

<img src="img/command_repl2.png" width="650">  


Runnning on demand the repl we created:  

<img src="img/command_run_repl.png" width="400">  


You can run repls and supply parameters to the repl that will be executed on the same session just before the repl. [More info](https://github.com/MarioRuiz/slack-smart-bot/issues/60)  
Example:
>**_Peter>_** ``run repl Create10RandomUsers `request = {path: '/api-dev/users/'}` ``  

If you want to add a collaborator while you are on a repl call `add collaborator @USER`. From that moment that user will be able to interact with the repl. You can add all the collaborators you want. When any collaborator wants to jump off the repl, that user can use the `quit` command.  

Other REPL commands: `see repls`, `run repl SESSION_NAME ENV_VAR=value`, `get repl SESSION_NAME`, `delete repl SESSION_NAME`, `kill repl RUN_REPL_ID`

### Sending notifications
> for admins

You can send notifications from MASTER CHANNEL by using **_`notify MESSAGE`_**. All Bot Channels will be notified.

If you want to send a notification message to all channels the bot joined and direct conversations with the bot: **_`notify all MESSAGE`_**

And if you want to send a notification message to the specified channel and to its extended channels: **_`notify #CHANNEL MESSAGE`_**

### Shortcuts
> for all users

Sometimes your commands or rules are too long and you want to add a shortcut to be executed.

If you have for example a rule like this: **_`run tests on customers android app`_** and you want to add a shortcut: **_`add shortcut run tca: run tests on customers android app`_**

From that moment you will be able to run the command: **_`run tca`_**

That shortcut will be available for you, in case you want to make it available for everybody on the channel: 

Example:  

<img src="img/command_add_sc.png" width="650">  


In case you want to use a shortcut as a inline shortcut inside a command you can do it by adding a $:
Example:
>**_Peter>_** `!add shortcut cust1: 3488823-1233`  
>**_Smart-Bot>_** `shortcut added`  
>**_Peter>_** `!add shortcut cust2: 1111555-6688`  
>**_Smart-Bot>_** `shortcut added`  
>**_Peter>_** `!run tests $cust1`  
>**_Smart-Bot>_** `Running tests for customers 3488823-1233`  
>**_Peter>_** `!run tests $cust1 $cust2`  
>**_Smart-Bot>_** `Running tests for customers 3488823-1233 1111555-6688`  

To see available shortcuts: **_`see shortcuts`_** and to delete a particular shortcut: **_`delete shortcut NAME`_**

### Announcements
> for all users

You can add any announcement on any channel where the SmartBot is a member by using **_`add COLOR announcement MESSAGE`_** or **_`add EMOJI announcement MESSAGE`_**.

It will store the message on the announcement list labeled with the color/emoji specified, white by default. Possible colors white, green, yellow and red. Aliases for announcement: statement, declaration, message.

Examples:
>**_Peter>_** `add green announcement :heavy_check_mark: All customer services are *up* and running`  
>**_Peter>_** `add red message Customers db is down :x:`  
>**_Peter>_** `add yellow statement Don't access the linux server without VPN`  
>**_Peter>_** `add announcement Party will start at 20:00 :tada:`  
>**_Peter>_** `add :heavy_exclamation_mark: message Pay attention all DB are on maintenance until 20:00 GMT`  

To see the announcements of the channel: **_`see announcements`_**, **_`see COLOR announcements`_**, **_`see EMOJI announcements`_** and to delete a particular announcement: **_`delete announcement ID`_**  

<img src="img/command_see_announcements.png" width="650">  

If you are a master admin and you are on master channel then you can call **_`publish announcements`_** that will publish the announcements on all channels. The messages stored on a DM won't be published. This is very convenient to be called from a *Routine* for example every weekday at 09:00.

### Share messages
> for all users

You can automatically share any new message that is posted on the channel and meet the specified criteria by using **_`share messages /REGEXP/ on #CHANNEL`_** or **_`share messages "TEXT" on #CHANNEL`_**.

This command is only available in public channels. The user adding the Share and the SmartBot need to be a member of both channels.

Examples:
>**_Peter>_** `share messages /(last\s+|previous\s+)?sales\s+results\s+/ on #sales`  
>**_Peter>_** `share messages "share post" on #announcements`  

To see the shares of the channel: **_`see shares`_** and to delete a particular share: **_`delete share ID`_**

### See statuses
> for all users

To see a list of statuses of the members in the channel you can call `see statuses`, `who is on vacation?`, `who is not on vacation?`, `who is on EMOJI`, `who is on EMOJI #CHANNEL`

You need to be a member of the channel to be able to get this info.

Examples:
>**_Peter>_** `see statuses`  
>**_Peter>_** `who is on vacation?`  
>**_Peter>_** `who is not on vacation?`  
>**_Peter>_** `who is on vacation? #SalesChannel`  
>**_Peter>_** `who is on :working-from-home:`  
>**_Peter>_** `who is available?`  

<img src="img/command_see_statuses.png" width="400">  

### Routines
> for admins

To add specific commands to be run automatically every certain amount of time or a specific time: **_`add routine NAME every NUMBER PERIOD COMMAND`_** or **_`add routine NAME at TIME COMMAND`_**. Also just before the command you can supply the channel where you want to publish the results, if not channel supplied then it would be the SmartBot Channel or on the DM if the command is run from there. Remember the SmartBot needs to have access to the channel where you want to publish.

In case you create a *bgroutine* instead of a normal *routine* then the results of the run won't be published.

If you want to hide the routine executions use `add silent routine`. It won't show the routine name when executing.

To see the last result of the execution you can call `see result routine NAME`

Examples:  
>**_`add routine run_tests every 3h !run tests on customers`_**  
>**_`add bgroutine clean_db at 17:05 !clean customers temp db`_**  
>**_`add silent bgroutine clean_db at 17:05 !clean customers temp db`_**  
>**_`add routine clean_custdb on Mondays at 05:00 !clean customers db`_**  
>**_`add routine clean_custdb on Tuesdays at 09:00 #SREChannel !clean customers db`_**  
>**_`add silent routine suggestions on weekdays at 09:00 suggest command`_**
>**_`add routine example on the 31st at 20:00 ^results sales monthly`_**  

Also instead of adding a Command to be executed, you can attach a file, then the routine will be created and the attached file will be executed on the criteria specified. Also you can supply a script adding \`\`\`the code\`\`\` and specifying on the routine name the extension that will have. Only Master Admins are allowed to add files or scripts.

Other routine commands:
* **_`pause routine NAME`_**
* **_`start routine NAME`_**
* **_`remove routine NAME`_**
* **_`run routine NAME`_**
* **_`see routines`_**
* **_`see result routine NAME`_**

### Loops
> for all users

You can run *any command* or rule on a loop by using:  
**_`for NUMBER times every NUMBER minutes COMMAND`_**  
**_`for NUMBER times every NUMBER seconds COMMAND`_**  
Maximum number of times to be used: 24. Minimum every 10 seconds. Maximum every 60 minutes.  

To stop the execution of a loop you can use: **_`quit loop LOOP_ID`_**  
Examples:  
>**_`for 5 times every 1 minute ^ruby puts Time.now`_**  
>**_`10 times every 30s !ruby puts Time.now`_**  
>**_`24 times every 60m !get sales today`_**  
>**_`quit loop 1`_**  
>**_`stop iterator 12`_**  

<img src="img/command_loop.png" width="500">  

### Control who has access to a command
> for admins

You can add, remove and list admins of any channel by using: `add admin @user`, `remove admin @user` and `see admins`. You need to be the creator of the channel, a Master admin or an admin.

To see the full list of available command ids on any channel call: `see command ids`

If you want to define who has access to certain commands in all SmartBot instances, you can specify it on the settings when starting the Smart Bot:

```ruby
settings = {
    # the channel that will act like the master channel, main channel
    master_channel: 'my_master_channel',
    masters: ["mario"], #names of the master users
    token: 'xxxxxxxxxxxxxxxxxx', # the API Slack token
    allow_access: {
      repl: [ 'marioruiz', 'peterlondon', 'UMYAAS8E7F'],
      ruby_code: [ 'marioruiz', 'UMYAAS8E7F', 'samcooke']
    }
}
```
You can use the user name or the user id.

If you want to change who has access to a specific command without restarting the Smart Bot you can do it on the rules file, for example:

```ruby
        # helpadmin: ----------------------------------------------
        # helpadmin: `update access`
        # helpadmin:      It will update the privileges to access commands or rules
        # helpadmin:      
      when /\A\s*update\s+access\s*\z/i
        save_stats(:update_access)
        if is_admin?()
          config.allow_access.repl = ['marioruiz', 'samcooke']
          respond "updated on <##{@channel_id}>!"
        else
          respond 'Only admins can change the access rules'
        end
```

To check from a rule if the user has access to it:

```ruby
if has_access?(:your_command_id)
end
```

Also you can allow or deny access for specific commands and users on any specific channel all you need is the Smartbot to be a member of the channel and use these commands on Slack:  
`allow access COMMAND_ID`  
`allow access COMMAND_ID @user1 @user99`  
It will allow the specified command to be used on the channel.  
If @user specified, only those users will have access to the command  
Only admins of the channel can use this command.  

`deny access COMMAND_ID`  
It won't allow the specified command to be used on the channel.  
Only admins of the channel can use this command  

`see access COMMAND_ID`  
it will show the access rights for the specified command  

The authorization is controlled by `save_stats` so it will be check out when calling `save_stats` or by calling `has_access?(:your_command_id)`

### See favorite commands
> for all users

It will display the favorite commands in that channel. 

Examples:  
>**_`see favorite commands`_**  
>**_`favorite commands`_**  
>**_`my favourite commands`_**  
>**_`most used commands`_**  

### Teams
> for all users  

For a quick introduction play this video:  
[![SmartBot Teams](https://img.youtube.com/vi/u8B4aGDXH9M/0.jpg)](https://www.youtube.com/watch?v=u8B4aGDXH9M)  

You can add, update, see, ping and delete teams. When calling `see TEAM_NAME team` the availability of the members will be displayed.  
`add team TEAM_NAME PROPERTIES` will add a team with the info supplied. In case it is supplied a channel with type 'members' the members of that channel would be considered members of the team.  

Examples:  
>**_`add team devweb members #devweb support #devweb-support : We take care of the website`_**  
>**_`add team devweb qa @jim dev @johnja @cooke @luisa members #devweb support #devweb-support : We take care of the website`_**  
>**_`add team sandex manager @sarah members #sandex : We take care of the sand`_**  

By calling `update team` you will update a team with the info supplied.  

Examples:  
>**_`update team sales : Support for customers`_**  
>**_`update sales team delete @sarah @peter`_**  
>**_`update sales team add public #salesff`_**  
>**_`update sales team add qa @john @ben @ana`_**  

It is possible to search teams by user, info, channel or team name. In case calling `see team TEAM_NAME` or `TEAM_NAME team` it will show also the availavility of the members: on vacation, in a meeting, sick leave, away or available.  

Examples:  
>**_`see teams`_**  
>**_`see Sales team`_**  
>**_`which teams #salesff`_**  
>**_`which teams @sarah`_**  
>**_`which team does @john belongs to?`_**  

By calling `ping team TEAM_NAME TYPE_MEMBER MESSAGE` will send the MESSAGE naming all available members of the MEMBER_TYPE supplied.  
If you call `contact team TEAM_NAME TYPE_MEMBER MESSAGE` will send the MESSAGE naming all members of the MEMBER_TYPE supplied.  

Examples:  
>**_`ping team sales development What's the status  on last deployment?`_**  
>**_`contact team sales qa Please finish testing of dev02 feature before noon`_**  

It is also possible to add notes for the team, even you can specify if those notes are private so only the members of the team can see them or even personal so only you will. You can use different types of notes: memo, note, issue, task, feature, bug, jira, github. Also you can indicate the topic of the note. To be able to add or delete notes you need to be a member of that team.   
In case of 'jira' type then you can supply an URL or a JQL and it will show all the JIRA issues as memos. To be able to use it you need to specify on the SmartBot settings the credentials for the Basic Authentication on JIRA:
`jira: {host: HOST, user: USER, password: PASSWORD}`  
In case of 'github' type then you can supply an URL filtering the Github issues you want to add as memos. To be able to use it you need to specify on the SmartBot settings the Github token:
`github: {token: GITHUB_TOKEN}`  

If you want to change the memo status use the command `set STATUS on memo ID TEAM_NAME team`. For example: `set :runner: on memo 7 Sales team`  

You can add also comments to any memo by calling: `team TEAM_NAME memo ID MESSAGE`. To see a specific memo and all the comments: `team TEAM_NAME memo ID`. In case of a Jira or GitHub memo then it will show also the comments in there.  

Examples:  
>**_`add memo to sales team : Add tests for Michigan feature`_**  
>**_`add private note to sales team : Bills will need to be deployed before Friday`_**  
>**_`add memo to dev team web : Check last version`_**  
>**_`add private bug to dev team SRE : Logs should not be accessible from outside VPN`_**  
>**_`add memo sales team : Add tests for Michigan feature`_**  
>**_`add memo team sales: Add tests for Michigan feature`_**  
>**_`add jira to sales team : labels = SalesT AND status != Done`_**  
>**_`add github to sales team : https://github.com/PeterBale/SalesBoom/issues?q=is%3Aissue+is%3Aopen+`_**  
>**_`set :runner: on memo 7 team Sales`_**  
>**_`see all memos from Sales team`_**  
>**_`see bugs from Sales team dev`_**  
>**_`sales team memo 4 Put it on hold until tests for Apple feature are finished`_**  
>**_`sales team memo 7`_**  

<img src="img/command_see_team.png" width="650">  


Other team commands: **_`delete team TEAM_NAME`_**, **_`delete memo ID from team TEAM_NAME`_**, **_`set STATUS on memo ID TEAM_NAME team`_**, **_`see MEMO_TYPE from TEAM_NAME team TOPIC`_**  


### Time off management
> for all users

You will be able to add or remove vacation and sick periods by using `add vacation/sick from YYYY/MM/DD to YYYY/MM/DD`. The SmartBot will automatically set the users status to 🌴 or 🤒 and the expiration date when the user is on vacation or sick. The SmartBot won't be allowed to change the status of workspace admins or owners.  

The vacation plan will be displayed also with the team when calling `see team NAME` for all team members.  

Also, you can see the vacation plan for the team for a specific period: `vacations team NAME YYYY/MM/DD`  

To be able to use this command you need to allow the 'users.profile:write' scope on your Slack App and an admin user of the workspace needs to install the app. Set the user token provided by the workspace on the SmartBot settings:  

```ruby
settings = {
  user_token: ENV['SLACK_USER_TOKEN']
}
```

If you want to see the public holidays for a specific country or country/region you can use the command `public holidays COUNTRY/REGION`. Examples: `public holidays Iceland`, `public holidays Spain/Madrid`, `public holidays United States/California 2024`, `public holidays Spain/Catalonia 2024/04`.  
You need to set up an account on https://www.calendarific.com  
Add to your Smartbot configuration:
```ruby
settings = {
  public_holidays: { 
      api_key: ENV['CALENDARIFIC_API_KEY']
  }
}
```

When calling `see my time off` on a DM will display a calendar of the year with the days off, including public holidays  

<img src="img/command_my_timeoff.png" width="750">

Other 'time off' commands: **_`remove time off ID`_**, **_`see my time off`_**, **_`see vacations @USER`_**, **_`time off team NAME`_**, **_`set public holidays to COUNTRY/REGION`_**    


### OpenAI

#### OpenAI setup
> for admins  

To be able to use this SmartBot general command you need to ask for an API token: https://platform.openai.com/account/api-keys or supply a Host and api_key for Azure OpenAI.    

Then specify in the SmartBot config the keys:  

```ruby
ai: {
  # for all open_ai services
  open_ai: {
      #default host and token for all openAI services
      host: 'HOST', # optional
      access_token: 'OPENAI_ACCESS_TOKEN',
      # Optional. For chatGPT. If supplied it will be used instead of the ones defined for all open_ai services
      chat_gpt: { 
        host: 'HOST',
        access_token: 'OPENAI_ACCESS_TOKEN', #or OPENAI_API_KEY from Azure
        api_type: :openai_azure, #Default type will be :openai (possible values are :openai, :openai_azure) 
                             #If supplied :openai_azure then it is necessary to supply host
        api_version: '2023-03-15-preview', # Default api version for :openai_azure
        model: 'gpt-3.5-turbo',
        smartbot_model: 'gpt-3.5-turbo'
      },
      # Optional. For DALL-E. If supplied it will be used instead of the ones defined for all open_ai services
      dall_e: {
        host: 'HOST',
        access_token: 'OPENAI_ACCESS_TOKEN',
        image_size: '256x256',
      },
      # Optional. For Whisper. If supplied it will be used instead of the ones defined for all open_ai services
      whisper: {
        host: 'HOST',
        access_token: 'OPENAI_ACCESS_TOKEN',
        model: 'whisper-1',
      }
  }
}
```

Or if you want you can set your personal access token just to be used by you by calling on a DM with the SmartBot the command: `set personal settings ai.open_ai.access_token ACCESS_TOKEN`  
Also, you can specify personal settings for `host`, `ai.open_ai.chat_gpt.model`, `ai.open_ai.chat_gpt.smartbot_model`, `ai.open_ai.whisper.model` or `ai.open_ai.dall_e.image_size`, instead of using the default values.  
For using different hosts or tokens for each service you can use the `chat_gpt`, `dall_e` or `whisper` keys.  

#### ChatGPT
> for all users  

For a quick introduction play this video:  
[![SmartBot ChatGPT](https://img.youtube.com/vi/zri_R6sLtBA/0.jpg)](https://www.youtube.com/watch?v=zri_R6sLtBA)  

`?? PROMPT`  
`? PROMPT`  
Chat GPT will generate a response based on the PROMPT indicated.  
If ?? is used, it will start from zero the session. If not all the previous prompts from the session will be used to generate the response.  
You can share a message and use it as input for the supplied prompt.  

<img src="img/chat_gpt.png" width="650">  

<img src="img/chat_gpt_share.png" width="600">  


When using ?? a temporary chatGPT session will be created. If you want to start a session with a given name use `chatGPT SESSION_NAME`. You can add also the description of the session by using `chatGPT SESSION_NAME "DESCRIPTION"`.  
If you want to categorize your sessions you can use `chatGPT SESSION_NAME >TAG_NAME`.  
You can supply also a specific GPT model to be used. `chatGPT SESSION_NAME MODEL_NAME`.  
To get all prompts from a specific session name use `chatGPT get SESSION_NAME`.  
To list all sessions you created use `chatGPT sessions`.  
When starting a new session, if you ask SmartBot to answer on a Thread by using !! or ^, then it won't be necessary to send ? before the prompt. In this case, every single message you send will be considered a prompt to be treated. After 30 minutes of inactivity, SmartBot will stop listening to the thread. You will need to continue the session after that. If you want to avoid a message to be treated then start it with a hyphen '-'.  
To add a collaborator when on a thread, you can use directly `add collaborator @USER`  
If you include in the prompt `!URL` then it will download and use the content of the URL as input for the prompt. If the URL is a Google Drive link, it will download the content of the file. PDF, DOCX and text files (txt, json, yaml...) are supported.  
If you want to add static content to your session to be used: `add static content URL1 URL99`.  
Add live content to your session by using `add live content URL1 URL99`. The content will be downloaded and added to your session every time you send a new prompt.  
It is possible to specify authorizations tokens for any website you want to reach the content using ChatGPT command. When adding to your prompt `!URL` SmartBot will verify if the domain specified have set an authorization header and add it. To add personal authorization tokens you can do it calling on a DM the commands: `add personal settings authorizations.example.host example.com`, `add personal settings authorizations.example.authorization Xdddj33a_SDFBBBS33Ab`  
Also you can add authorizations on a specific ChatGPT session: `add authorization HOST HEADER VALUE`, for example: `add authorization api.example.com Authorization Bearer 123456`. If you share this session as public or for a specific channel, users will be able to send prompts for that session using your authorizations but they won't be able to see the auth values or copy those auth to a new chatgpt session.  
You can add messages from a channel to your session by using `add history #CHANNEL_NAME`.  

If you want to delete the last ChatGPT response and send again last prompt, you can use `resend prompt`.  
You can set the context of your ChatGPT session: `set context CONTEXT`. Example: `set context You are a funny comedian who tells dad jokes. The output should be in JSON format.`  

Also if you are using a model that allows you to add images to your prompt (fex gpt-4o), you can attach any images.    

<img src="img/chat_gpt_attach_image.png" width="500">  
  
When on a thread you can change the model to be used by sending `use model MODEL_NAME`. For a temporary session if you want to create the session with a specific model use `?? use model MODEL_NAME`. The model supplied can be a substring of the model name, SmartBot will try to find the model that matches the substring.    

<img src="img/chat_gpt_session.png" width="650">  

You can copy your session by using `chatGPT copy SESSION_NAME NEW_SESSION_NAME`.  
To share your session with everyone use `chatGPT share SESSION_NAME`. Then the session will be available for everyone to use. If you prefer to share it with a specific channel use `chatGPT share SESSION_NAME #CHANNEL`. In that case, only the users on that channel will be able to use the session.  
To list all public sessions call `chatGPT public sessions`. To list all shared sessions in a channel, from that channel call `chatGPT shared sessions`. You can also filter the sessions by tag, for example, `chatGPT public sessions >TAG_NAME`.  
If you want to use any public or shared session, you can use `chatGPT use USER_NAME SESSION_NAME` or `chatGPT use USER_NAME SESSION_NAME NEW_SESSION_NAME`.  
To remove any shared session from the list, call `chatGPT stop sharing SESSION_NAME` or `chatGPT stop sharing SESSION_NAME #CHANNEL`.  

Play this video:  
[![SmartBot ChatGPT Share Sessions](https://img.youtube.com/vi/Mnve3tnEd-8/0.jpg)](https://www.youtube.com/watch?v=Mnve3tnEd-8)  

It is possible to use a session that is public, private or shared with a channel as a temporary session: `?? use SESSION_NAME PROMPT`. For example: `?? use lunch What's for Thursday?`. This will create a temporary session using the session named as `lunch` and send the prompt `What's for Thursday?`  

You can also use ChatGPT when creating REPLs. During the REPL session you can ask *ChatGPT* about the code or any other question. Just start the message with `?` and the Smart Bot will ask ChatGPT and will post the answer. Example: `? How to create a new customer?`. If you send just the question mark without a prompt then ChatGPT will suggest next code line. Example: `?`  
To send the results of a *SmartBot command* as input for a *ChatGPT* session, use `COMMAND ?? PROMPT`. Example: `bot help ?? how can I use the time off commands`. If you are on a thread you can send more SmartBot commands to the same session by using `COMMAND ?? PROMPT`.   

##### Docs Folder for ChatGPT Sessions
> For admins  

Doc folders can be added by admins for specific chatgpt sessions. SmartBot will filter those docs depending on the prompt and attach them along with the prompt.  
Put all docs as text files on `./openai/TEAM_ID/USER_NAME/SESSION_NAME/docs_folder`.  
For the documents to be filtered add them to `filter` subfolder under `docs_folder`.  
For the documents to be added always to the prompts, add them to `include` subfolder under `docs_folder`.  
Inside those subfolders you can organize the documents the way you want.  

##### Restrict who has access to a specific model
> For admins  

You can add a file named restricted_models.yaml on ./openai folder supplying the models and users that will have access to specific models.  
  Example of content:  
    o1-mini: [rmario, peter]  
    o1-preview: [rmario]  

#### Image Generation
> for all users  

`??i PROMPT`  
 `?i PROMPT`  
 `?ir`  
It will generate an image based on the PROMPT indicated.  
If `??i` is used, it will start from zero the session. If not all the previous prompts from the session will be used to generate the image.  
if using `?ir` will generate a new image using the session prompts.  

<img src="img/image_generation.png" width="400">  

#### Image Variations
> for all users  

`?iv`  
`?ivNUMBER`  
It will generate a variation of the last image generated in the session.  
In the case of NUMBER, it will generate NUMBER of variations of the last image generated. NUMBER needs to be between 1 and 9.  
If an image is attached then it will generate temporary variations of the attached image.  

<img src="img/image_variations.png" width="400">  

#### Image Editing
> for all users  

`?ie PROMPT`  
It will edit the attached image with the supplied PROMPT. The supplied image needs to be an image with a transparent area.  
The PROMPT need to explain the final result of the image.  

<img src="img/image_editing.png" width="400">  

#### Whisper
> for all users  

`?w PROMPT`  
`?w`  
It will transcribe the audio file attached and perform the PROMPT indicated if supplied.  

<img src="img/whisper.png" width="650">  

#### Models
> for all users  

`?m`  
`?m MODEL`  
`chatgpt models`  
It will return the list of models available or the details of the model indicated.  

### Recap
> for all users  

`recap`  
`my recap`  
`recap from YYYY/MM/DD`  
`recap from YYYY/MM/DD to YYYY/MM/DD`  
`recap YYYY`  
`recap #CHANNEL`  
`my recap #CHANNEL`  
`recap from YYYY/MM/DD #CHANNEL`  
`recap from YYYY/MM/DD to YYYY/MM/DD #CHANNEL`  
`recap YYYY #CHANNEL`  
It will show a recap of the channel. If channel not supplied, it will show the recap of the current channel.  
If 'my' is added, it will show also a recap of your messages.  
If only one date is added, it will show the recap from that day to 31st of December of that year.  
If only one year is added, it will show the recap from 1st of January to 31st of December of that year.  
Examples:  
>**_`recap`_**  
>**_`my recap`_**  
>**_`recap 2023`_**  
>**_`recap from 2023/07/01 to 2023/12/31 #sales`_**  
>**_`recap 2022 #sales`_**  

<img src="img/command_recap.png" width="250">  

### Summarize
> for all users  

`summarize`  
`summarize since YYYY/MM/DD`  
`summarize #CHANNEL`  
`summarize #CHANNEL since YYYY/MM/DD`  
`summarize URL_THREAD`  
It will summarize using ChatGPT the messages in the channel since the date specified.  
If no date is specified it will summarize the last 30 days.  
If time off added using Time Off command it will summarize since your last time off started.  
If no channel is specified it will summarize the current channel.  
If a thread URL is specified it will summarize the thread.  
If the command is used in a thread it will summarize the thread.  
Examples:  
>**_`summarize`_**  
>**_`summarize since 2024/01/22`_**  
>**_`summarize #sales`_**  
>**_`summarize #sales since 2024/01/22`_**  
>**_`summarize https://yourcompany.slack.com/archives/C111JG4V4DZ/p1622549264010700`_**  

<img src="img/command_summarize.png" width="500">  

### Personal Settings  
On a DM with SmartBot you can call `set personal settings` command and supply your specific personal settings just for you. Then the command using those settings will be specific for you with the value indicated here.   
Examples:  
>**_`set personal settings ai.open_ai.access_token Axdd3SSccffddZZZDFFDxf7`_**  
>**_`set personal settings ai.open_ai_chat_gpt.model gpt-4-turbo-preview`_**  
>**_`set personal settings authorizations.confluence.host confluence.love.example.com`_**  
>**_`set personal settings authorizations.confluence.authorization Bearer XDfjjdkAAAjjjdkkslsladjjjd`_**  

Other commands: `delete personal settings SETTINGS_ID`, `get personal settings`, `get personal settings SETTINGS_ID`  

### Tips
> for admins

#### Send a file

```ruby
    #send_file(to, msg, filepath, title, format, type = "text")
    send_file(dest, 'the message', "#{project_folder}/temp/logs_ptBI.log", 'title', 'text/plain', "text")
    send_file(dest, 'the message', "#{project_folder}/temp/example.jpeg", 'title', 'image/jpeg', "jpg")
```

#### Download a file

When uploading a file the message added to 'Add a message about the file' will be the command treated by the bot rule. Then in your rules file:

```ruby
    when /^do something with my file/i
      if !files.nil? and files.size == 1 and files[0].filetype == 'yaml'
        require "nice_http"
        http = NiceHttp.new(host: "https://files.slack.com", headers: { "Authorization" => "Bearer #{config.token}" })
        res = http.get(files[0].url_private_download, save_data: './tmp/')
        # if you want to directly access to the content use: `res.data`
      end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marioruiz/slack-smart-bot.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

