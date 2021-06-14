# Slack Smart Bot

[![Gem Version](https://badge.fury.io/rb/slack-smart-bot.svg)](https://rubygems.org/gems/slack-smart-bot)
[![Build Status](https://travis-ci.com/MarioRuiz/slack-smart-bot.svg?branch=master)](https://github.com/MarioRuiz/slack-smart-bot)
[![Coverage Status](https://coveralls.io/repos/github/MarioRuiz/slack-smart-bot/badge.svg?branch=master)](https://coveralls.io/github/MarioRuiz/slack-smart-bot?branch=master)

Create a Slack bot that is really smart and so easy to expand.

The main scope of this ruby gem is to be used internally in your company so teams can create team channels with their own bot to help them on their daily work, almost everything is suitable to be automated!!

slack-smart-bot can create bots on demand, create shortcuts, run ruby code... just on a chat channel, you can access it just from your mobile phone if you want and run those tests you forgot to run, get the results, restart a server... no limits.

![](slack.png)

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
    + [REPL](#repl)
  * [Sending notifications](#sending-notifications)
  * [Shortcuts](#shortcuts)
  * [Routines](#routines)
  * [Limit who has access to a command](#limit-who-has-access-to-a-command)
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

    else
      unless processed
        dont_understand()
      end
  end
end
```

Also you can add general rules that will be available on all Smart Bot channels to `./rules/general_rules.rb`

If you have commands that want to make them available everywhere the Smart Bot is invited then add those commands to `./rules/general_commands.rb`. 

### How to access the Smart Bot
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
>**_Peter>_** `!ruby puts Time.now`  
>**_Smart-Bot>_** `2019-10-23 12:43:42 +0000`

>**_Peter>_** `@smart-bot echo Example`  
>**_Smart-Bot>_** `Example`

>**_Peter>_** `smart-bot see shortcuts`  
>**_Smart-Bot>_** `Available shortcuts for Peter:`  
>`Spanish account: ruby require 'iso/iban'; 10.times {puts ISO::IBAN.random('ES')}`  
>**_Peter>_** `!!echo Example`  
>. . . . . . . . .**_Smart-Bot>_** `Example`  
>**_Peter>_** `^echo Example`  
>. . . . . . . . .**_Smart-Bot>_** `Example`

Also you can always call the Smart Bot from any channel, even from channels without a running Smart Bot. You can use the External Call on Demand: **_`@NAME_OF_BOT on #CHANNEL_NAME COMMAND`_**. In this case you will call the bot on #CHANNEL_NAME. You can supply more than one channel then all the bots will respond. In case you are in a private conversation with the Smart Bot (DM) then you can use directly:  **_`#CHANNEL_NAME COMMAND`_** or **_`on #CHANNEL_NAME COMMAND`_**

Examples:
>**_Peter>_** `@smart-bot on #the_channel ruby puts Time.now`  
>**_Smart-Bot>_** `2019-10-23 12:43:42 +0000`  
>**_Peter>_** `@smart-bot on #the_channel ^ruby puts Time.now`  
>. . . . . . . . .**_Smart-Bot>_** `2019-10-23 12:43:42 +0000`

Examples on DM:
>**_Peter>_** `#sales show report from India`
>**_Peter>_** `on #sales notify clients`

If you want the Smart Bot just listen to part of the message you send, add the commands you want using '`' and start the line with '-!', '-!!' or '-^'

Examples:
>**_Peter>_** ``-!This text won't be treated but this one yes `ruby puts 'a'` and also this one `ruby puts 'b'` ``  
>**_Smart-Bot>_** `a`  
>**_Smart-Bot>_** `b`

>**_Peter>_** ``-^This text won't be treated but this one yes `ruby puts 'a'` and also this one `ruby puts 'b'` ``  
>. . . . . . . . .**_Smart-Bot>_** `a`  
>. . . . . . . . .**_Smart-Bot>_** `b`


All the commands specified on `./rules/general_commands.rb` will be accessible from any channel where the Smart Bot is present, without the necessity to call it with !, !!, ^ or on demand.

Examples:
>**_Peter>_** `Thanks smartbot`  
>**_Smart-Bot>_** `You're very welcome`  

### Bot Help
To get a full list of all commands and rules for a specific Smart Bot: **_`bot help`_**. It will show only the specific available commands for the user requesting. By default it will display only a short version of the bot help, call **_`bot help expanded`_** to get a expanded version of all commands.

If you want to search just for a specific command: **_`bot help COMMAND`_** It will display expanded explanations for the command.

To show only the specific rules of the Smart Bot defined on the rules file: **_`bot rules`_** or **_`bot rules COMMAND`_**

Also you can call `suggest command` or `random command` and SmartBot will return the help content for a random command.

Example:
>**_Peter>_** `bot help echo`  
>**_Smart-Bot>_** `echo SOMETHING`  
    `repeats SOMETHING`

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

To see what's new just call `What's new`

### Bot Management
To create a new bot on a channel, run on MASTER CHANNEL: **_`create bot on CHANNEL`_**. The admins of this new bot on that channel will be the MASTER ADMINS, the creator of the bot and the creator of that channel. It will create a new rules file linked to this new bot.

You can kill any bot running on any channel if you are an admin of that bot: **_`kill bot on CHANNEL`_**

If you want to pause a bot, from the channel of the bot: **_`pause bot`_**. To start it again: **_`start bot`_**

To see the status of the bots, on the MASTER CHANNEL: **_`bot status`_**

If you need it you can set the SmartBot on maintenance mode by running: **_`set maintenance on`_**. A message to be displayed can be added if not the default message will be used. Run **_`set maintenance off`_** when you want the SmartBot to be running in normal conditions again.

To display a general message after every command use: `set general message MESSAGE`. Use `set general message off` to stop displaying it.

To close the Master Bot, run on MASTER CHANNEL: **_`exit bot`_**

If you are a Master Admin on a Direct Message with the Smart Bot you can call the **_`bot stats`_** and get use stats of the users. You need to set to `true` the `stats` settings when initializing the Smart Bot. As a normal user you will get your own stats when calling **_`bot stats`_**. Take a look at `bot help bot stats` for more info. Also you can call **_`leaderboard`_** to get some useful information about the use of the SmartBot.

You can also get the bot logs of the bot channel you are using by calling `get bot logs`. You need to be a Master Admin user on a DM with the Smart Bot.

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

#### REPL
Easily starts a REPL session so you will be able to create a script directly from the slack conversation. You will be able to share the REPL so they can run it or see the content.

It Will run all we write as a ruby command and will keep the session values until we finish the session sending `quit`, `exit` or `bye` 

You can specify a SESSION_NAME that admits from a to Z, numbers, - and _. If no SESSION_NAME supplied it will be treated as a temporary REPL.
If 'private' specified in the command the REPL will be accessible only by you and it will be displayed only to you when `see repls`

To avoid a message to be treated when a session started, start the message with '-'.

Send puts, print, p or pp if you want to print out something when using `run repl` later.

If you declare on your rules file a method called `project_folder` returning the path for the project folder, the code will be executed from that folder. 

By default it will be automatically loaded the gems: `string_pattern`, `nice_hash` and `nice_http`

To pre-execute some ruby when starting the session add the code to `.smart-bot-repl` file on the project root folder defined on `project_folder`. Then that file will be always executed before the REPL started or created. In that case if we want to avoid to run that file before the REPL we can do it adding the word 'clean' before the command `clean repl`.

If you want to see the methods of a class or module you created use `ls TheModuleOrClass`

You can supply the Environmental Variables you need for the Session

Examples:  
  _repl CreateCustomer LOCATION=spain HOST='https://10.30.40.50:8887'_  
  _repl CreateCustomer: "It creates a random customer for testing" LOCATION=spain HOST='https://10.30.40.50:8887'_  
  _repl delete\_logs_  
  _private repl random-ssn_  
  _repl_


Running Example:
>**_Peter>_** `!repl Create10RandomUsers: "This is just an example"`  
>**_Smart-Bot>_** `Session name: *Create10RandomUsers*`  
>**_Peter>_** `http = NiceHttp.new("https://reqres.in/")`  
>**_Smart-Bot>_** `#<NiceHttp:0x00007fc6e216e328 @host="reqres.in", @port=443...>`  
>**_Peter>_** `request = { path: '/api/users' }`  
>**_Smart-Bot>_** `{ :path => "/api/users" }`  
>**_Peter>_** `request.data = { name: '1-10:L', job: 'leader|worker' }`  
>**_Smart-Bot>_** `{ :name => "1-10:L", :job => "leader|worker" }`  
>**_Peter>_** `request.data.generate`  
>**_Smart-Bot>_** `{ :name => "kLam", :job => "leader" }`  
>**_Peter>_** `10.times { http.post(request.generate) } `  
>**_Smart-Bot>_** `10`  
>**_Peter>_** `puts "10 Random Users Created"`  
>**_Smart-Bot>_** `10 Random Users Created`  
>**_Peter>_** `quit`  
>**_Smart-Bot>_** `REPL session finished: Create10RandomUsers`  


>**_Peter>_** `run repl Create10RandomUsers`  
>**_Smart-Bot>_** `Running REPL Create10RandomUsers`  
>**_Smart-Bot>_** `Create10RandomUsers: 10 Random Users Created`  


Other REPL commands: `see repls`, `run repl SESSION_NAME ENV_VAR=value`, `get repl SESSION_NAME`, `delete repl SESSION_NAME`

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
>**_John>_** `!spanish bank account`  
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

Also instead of adding a Command to be executed, you can attach a file, then the routine will be created and the attached file will be executed on the criteria specified. Only Master Admins are allowed to use it this way.

Other routine commands:
* **_`pause routine NAME`_**
* **_`start routine NAME`_**
* **_`remove routine NAME`_**
* **_`run routine NAME`_**
* **_`see routines`_**
* **_`see result routine NAME`_**

### Limit who has access to a command

If you want to define who has access to certain commands you can specify it on the settings when starting the Smart Bot:

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

If you want to change who has access to a certain command without restarting the Smart Bot you can do it on the rules file:

```ruby
config.allow_access.repl = ['marioruiz', 'samcooke']
```

These are the commands that are possible to be limited:

`bot_help, bot_rules, bot_status, use_rules, add_shortcut, delete_shortcut, repl, run_repl, get_repl, delete_repl, see_repls, ruby_code, see_shortcuts, create_bot`


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
        http = NiceHttp.new(host: "https://files.slack.com", headers: { "Authorization" => "Bearer #{config.token}" })
        res = http.get(files[0].url_private_download, save_data: './tmp/')
        # if you want to directly access to the content use: `res.data`
      end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marioruiz/slack-smart-bot.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

