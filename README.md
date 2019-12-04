# Slack Smart Bot

[![Gem Version](https://badge.fury.io/rb/slack-smart-bot.svg)](https://rubygems.org/gems/slack-smart-bot)
[![Build Status](https://travis-ci.com/MarioRuiz/slack-smart-bot.svg?branch=master)](https://github.com/MarioRuiz/slack-smart-bot)
[![Coverage Status](https://coveralls.io/repos/github/MarioRuiz/slack-smart-bot/badge.svg?branch=master)](https://coveralls.io/github/MarioRuiz/slack-smart-bot?branch=master)

Create a Slack bot that is really smart and so easy to expand.

The main scope of this ruby gem is to be used internally in your company so teams can create team channels with their own bot to help them on their daily work, almost everything is suitable to be automated!!

slack-smart-bot can create bots on demand, create shortcuts, run ruby code... just on a chat channel, you can access it just from your mobile phone if you want and run those tests you forgot to run, get the results, restart a server... no limits.

# Table of Contents

- [Installation and configuration](#installation-and-configuration)
- [Usage](#usage)
  * [creating the MASTER BOT](#creating-the-master-bot)
  * [How to access the Smart Bot](#how-to-access-the-smart-bot)
  * [Bot Help](#bot-help)
  * [Bot Management](#bot-management)
    + [Cloud Bots](#cloud-bots)
  * [Extending rules to other channels](#extending-rules-to-other-channels)
  * [Using rules from other channels](#using-rules-from-other-channels)
  * [Running Ruby code on a conversation](#running-ruby-code-on-a-conversation)
  * [Sending notifications](#sending-notifications)
  * [Shortcuts](#shortcuts)
  * [Routines](#routines)
  * [Tips](#tips)
    + [Send a file](#send-a-file)
    + [Download a file](#download-a-file)
- [Contributing](#contributing)
- [License](#license)

## Installation and configuration

    $ gem install slack-smart-bot
    
After you install it you will need just a couple of things to configure it.

Create a file like this on the folder you want:

```ruby

require 'slack-smart-bot'

settings = {
    # the channel that will act like the master channel, main channel
    master_channel: 'my_master_channel',
    masters: ["mario"], #names of the master users
    token: 'xxxxxxxxxxxxxxxxxx' # the API Slack token
}

puts "Connecting #{settings.inspect}"
SlackSmartBot.new(settings).listen

```

The master_channel will be the channel where you will be able to create other bots and will have special treatment.

The masters will have full access to everything. You need to use the slack user name defined on https://YOUR_WORK_SPACE.slack.com/account/settings#username.

For the token remember you need to generate a token on the Slack web for the bot user.

You can get one by any of these options:

- *[Slack App. Bot Token](https://api.slack.com/slack-apps)*. (Recommended)

  1) [Create a Slack App](https://api.slack.com/apps?new_app=1)

  1) Add a bot user to your app. On Add features and functionality section for your app, select *Bots*. Click on *Add a Bot User*

  1) On your app click on the menu on the left: *OAuth & Permissions* and click on *Install App to Workspace*.

  1) Copy your *Bot User OAuth Access Token*.


- *[Legacy API Token](https://api.slack.com/custom-integrations/legacy-tokens)*. 


*Remember to invite the smart bot to the channels where they will be accessible before creating the bot*

## Usage

### creating the MASTER BOT
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

    # help: `go to sleep`
    # help:   it will sleep the bot for 10 seconds
    # help:
    when /^go\sto\ssleep/i
      unless @questions.keys.include?(from)
        ask "do you want me to take a siesta?"
      else
        case @questions[from]
          when /yes/i, /yep/i, /sure/i
            @questions.delete(from)
            respond "I'll be sleeping for 10 secs... just for you"
            respond "zZzzzzzZZZZZZzzzzzzz!"
            sleep 10
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

    else
      unless processed
        dont_understand()
      end
  end
end

```
### How to access the Smart Bot
You can access the bot directly on the MASTER CHANNEL, on a secondary channel where the bot is running and directly by opening a private chat with the bot, in this case the conversation will be just between you and the bot.

On a Smart Bot channel you will be able to run some of the commands just by writing a command, for example: **_`bot help`_**

Some commands will be only available when the Smart Bot is listening to you. For the Smart Bot to start listening to you just say: **_`hi bot`_**. When the Smart Bot is listening to you, you can skip a message to be treated by the bot by starting the message with '-', for example: **_`- this message won't be treated`_**. When you want the Smart Bot Stop listening to you: **_`bye bot`_**. If you are on a direct conversation with the Smart Bot then it will be on *listening* mode all the time.

All the specific commands of the bot are specified on your rules file and can be added or changed accordingly. We usually call those commands: *rules*. Those rules are only available when the bot is listening to you.

Another way to run a command/rule is by asking *on demand*. In this case it is not necessary that the bot is listening to you.

To run a command on demand:  
  **_`!THE_COMMAND`_**  
  **_`@NAME_OF_BOT THE_COMMAND`_**  
  **_`NAME_OF_BOT THE_COMMAND`_**  

Examples run a command on demand:
>**_Peter>_** `!ruby puts Time.now`  
>**_Smart-Bot>_** `2019-10-23 12:43:42 +0000`

>**_Peter>_** `@smart-bot echo Example`  
>**_Smart-Bot>_** `Example`

>**_Peter>_** `smart-bot see shortcuts`  
>**_Smart-Bot>_** `Available shortcuts for Peter:`  
>`Spanish account: ruby require 'iso/iban'; 10.times {puts ISO::IBAN.random('ES')}`

Also you can always call the Smart Bot from any channel, even from channels without a running Smart Bot. You can use the External Call on Demand: **_`@NAME_OF_BOT on #CHANNEL_NAME COMMAND`_**. In this case you will call the bot on #CHANNEL_NAME.

Example:
>**_Peter>_** `@smart-bot on #the_channel ruby puts Time.now`  
>**_Smart-Bot>_** `2019-10-23 12:43:42 +0000`



### Bot Help
To get a full list of all commands and rules for a specific Smart Bot: **_`bot help`_**. It will show only the specific available commands for the user requesting.

If you want to search just for a specific command: **_`bot help COMMAND`_**

To show only the specific rules of the Smart Bot defined on the rules file: **_`bot rules`_** or **_`bot rules COMMAND`_**

Example:
>**_Peter>_** `bot help echo`  
>**_Smart-Bot>_** `echo SOMETHING`  
    `repeats SOMETHING`

When you call a command that is not recognized, you will get suggestions from the Smart Bot.

Remember when you add code to your rules you need to specify the help that will be displayed when using `bot help`, `bot rules`

For the examples use _ and for the rules `. This is a good example of a Help supplied on rules source code:

```ruby
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

### Bot Management
To create a new bot on a channel, run on MASTER CHANNEL: **_`create bot on CHANNEL`_**. The admins of this new bot on that channel will be the MASTER ADMINS, the creator of the bot and the creator of that channel. It will create a new rules file linked to this new bot.

You can kill any bot running on any channel if you are an admin of that bot: **_`kill bot on CHANNEL`_**

If you want to pause a bot, from the channel of the bot: **_`pause bot`_**. To start it again: **_`start bot`_**

To see the status of the bots, on the MASTER CHANNEL: **_`bot status`_**

To close the Master Bot, run on MASTER CHANNEL: **_`exit bot`_**

#### Cloud Bots
If you want to create a bot that will be running on a different machine: **_`create cloud bot on CHANNEL`_**. Even though the cloud bots are running on different machines, the management can be done through the MASTER CHANNEL. The new cloud bot will be managed by your Master Bot like the others, closing, pausing...

Cloud Bots are typically used to run commands on specific environments or even different OS or networks.

### Extending rules to other channels
If you want to extend the use of your specific rules on a Bot Channel to a third channel you can use the command: **_`extend rules to CHANNEL`_**

From that moment everybody part of that channel will be able to run the specific rules from the other channel but just on demand, for example: **_`!run something`_**

To stop allowing it: **_`stop using rules on CHANNEL`_**

### Using rules from other channels
To be able to access the rules from other channel or from a direct conversation with the bot, first of all you need to be a member of that channel. Then on a direct conversation with the Smart Bot or from another bot channel: **_`use rules from CHANNEL`_**

When you want to stop using those rules with the bot: **_`stop using rules from CHANNEL`_**

Also you can always call the Smart Bot from any channel, even from channels without a running Smart Bot. You can use the External Call on Demand: **_`@NAME_OF_BOT on #CHANNEL_NAME COMMAND`_**. In this case you will call the bot on #CHANNEL_NAME.

### Running Ruby code on a conversation
You can run Ruby code by using the command: **_`ruby THE_CODE`_**. 

Example:
>**_Peter>_** `!ruby require 'json'; res=[]; 20.times {res.push rand(100)}; my_json={result: res}; puts my_json.to_json`  
>**_Smart-Bot>_** `{"result":[63,66,35,83,44,40,72,25,59,73,75,54,56,91,19,6,68,1,25,3]}`  

Also it is possible to attach a Ruby file and the Smart Bot will run and post the output. You need to select Ruby as file format.

### Sending notifications
You can send notifications from MASTER CHANNEL by using **_`notify MESSAGE`_**. All Bot Channels will be notified.

If you want to send a notification message to all channels the bot joined and direct conversations with the bot: **_`notify all MESSAGE`_**

And if you want to send a notification message to the specified channel and to its extended channels: **_`notify #CHANNEL MESSAGE`_**

### Shortcuts
Sometimes your commands or rules are too long and you want to add a shortcut to be executed.

If you have for example a rule like this: **_`run tests on customers android app`_** and you want to add a shortcut: **_`add shortcut run tca: run tests on customers android app`_**

From that moment you will be able to run the command: **_`run tca`_**

That shortcut will be available for you, in case you want to make it available for everybody on the channel: 
Example:
>**_Peter>_** `!add shortcut for all spanish bank account: ruby require 'iso/iban'; 3.times {puts ISO::IBAN.random('ES')}`  
>**_Smart-Bot>_** `shortcut added`  
>**_Peter>_** `!spanish bank account`  
>**_Smart-Bot>_** `ES4664553191352006861448`  
`ES4799209592433480943244`  
`ES8888795057132445752702`  

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

### Routines
To add specific commands to be run automatically every certain amount of time or a specific time: **_`add routine NAME every NUMBER PERIOD COMMAND`_** or **_`add routine NAME at TIME COMMAND`_**

If you want to hide the routine executions use `add silent routine`. It won't show the routine name when executing.

Examples:  
>**_`add routine run_tests every 3h !run tests on customers`_**  
>**_`add routine clean_db at 17:05 !clean customers temp db`_**  
>**_`add silent routine clean_db at 17:05 !clean customers temp db`_**  

Also instead of adding a Command to be executed, you can attach a file, then the routine will be created and the attached file will be executed on the criteria specified. Only Master Admins are allowed to use it this way.

Other routine commands:
* **_`pause routine NAME`_**
* **_`start routine NAME`_**
* **_`remove routine NAME`_**
* **_`run routine NAME`_**
* **_`see routines`_**

### Tips

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
        require 'nice_http'
        http = NiceHttp.new(host: "https://files.slack.com", headers: { "Authorization" => "Bearer #{config[:token]}" })
        res = http.get(files[0].url_private_download, save_data: './tmp/')
        # if you want to directly access to the content use: `res.data`
      end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marioruiz/slack-smart-bot.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

