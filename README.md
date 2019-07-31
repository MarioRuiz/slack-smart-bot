# Slack Smart Bot

[![Gem Version](https://badge.fury.io/rb/slack-smart-bot.svg)](https://rubygems.org/gems/slack-smart-bot)

Create a Slack bot that is really smart and so easy to expand.

The main scope of this ruby gem is to be used internally in your company so teams can create team channels with their own bot to help them on their daily work, almost everything is suitable to be automated!!

slack-smart-bot can create bots on demand, create shortcuts, run ruby code... just on a chat channel, you can access it just from your mobile phone if you want and run those tests you forgot to run, get the results, restart a server... no limits.

## Installation and configuration

    $ gem install slack-smart-bot
    
After you install it you will need just a couple of things to configure it.

Create a file like this on the folder you want:

```ruby
# the channel that will act like the master channel, main channel
MASTER_CHANNEL="my_master_channel"
#names of the master users
MASTER_USERS=["mario"]

require 'slack-smart-bot'

settings = {
    nick: 'my_smart_bot', # the smart bot name
    token: 'xxxxxxxxxxxxxxxxxx' # the API Slack token
}

begin
  puts "Connecting #{settings.inspect}"
  SlackSmartBot.new(settings).listen
rescue Exception => e
  puts "Rescued: #{e.inspect}"
end

```

The MASTER_CHANNEL will be the channel where you will be able to create other bots and will have special treatment.

The MASTER_USERS will have full access to everything. The names should be written exactly the same like they appear on Slack.

For the token remember you need to generate a token on the Slack web for the bot user.

This is something done in Slack, under [integrations](https://my.slack.com/services). Create a [new bot](https://my.slack.com/services/new/bot), and note its API token.

*Remember to invite the smart bot to the channels where they will be accessible before creating the bot*

## Usage

### creating the MASTER BOT
Let's guess the file you created was called my_smart_bot.rb so, just run it:
```
ruby my_smart_bot.rb
```

After the run, it will be generated a rules file with the same name but adding _rules, in this example: my_smart_bot_rules.rb

The rules file can be edited and will be only affecting this particular bot.

You can add all the rules you want for your bot in the rules file, this is an example:

```ruby
def rules(user, command, processed, dest)
  from = user.name
  firstname = from.split(" ").first
  case command

    # help: `echo SOMETHING`
    # help:     repeats SOMETHING
    # help:
    when /echo\s(.+)/i
      respond $1

    # help: `go to sleep`
    # help:   it will sleep the bot for 10 seconds
    # help:
    when /go\sto\ssleep/i
      unless @questions.keys.include?(from)
        ask("do you want me to take a siesta?", command, from)
      else
        case @questions[from]
          when /yes/i, /yep/i, /sure/i
            @questions.delete(from)
            respond "zZzzzzzZZZZZZzzzzzzz!"
            respond "I'll be sleeping for 10 secs... just for you"
            sleep 10
          when /no/i, /nope/i, /cancel/i
            @questions.delete(from)
            respond "Thanks, I'm happy to be awake"
          else
            respond "I don't understand"
            ask("are you sure do you want me to sleep? (yes or no)", "go to sleep", from)
        end
      end
    else
      unless processed
        resp = %w{ what huh sorry }.sample
        respond "#{firstname}: #{resp}?"
      end
  end
end

```
### How to access the smart bot
You can access the bot directly on the MASTER CHANNEL, on a secondary channel where the bot is running and directly by opening a private chat with the bot, in this case the conversation will be just between you and the bot.

### Available commands even when the bot is not listening to you
Some of the commands are available always even when the bot is not listening to you but it is running

**_`bot help`_**

**_`bot what can I do?`_**

>It will display all the commands we can use
>What is displayed by this command is what is written on your rules file like this: #help: THE TEXT TO SHOW

**_`Hello Bot`_**

**_`Hello THE_NAME_OF_THE_BOT`_**

>Also apart of Hello you can use Hallo, Hi, Hola, What's up, Hey, Hæ

>Bot starts listening to you

>If you want to avoid a single message to be treated by the smart bot, start the message by -

**_`Bye Bot`_**

**_`Bye THE_NAME_OF_THE_BOT`_**

>Also apart of Bye you can use Bæ, Good Bye, Adiós, Ciao, Bless, Bless Bless, Adeu

>Bot stops listening to you

**_`exit bot`_**

**_`quit bot`_**

**_`close bot`_**

>The bot stops running and also stops all the bots created from this master channel

>You can use this command only if you are an admin user and you are on the master channel

**_`start bot`_**

**_`start this bot`_**

>The bot will start to listen

>You can use this command only if you are an admin user

**_`pause bot`_**

**_`pause this bot`_**

>The bot will pause so it will listen only to admin commands

>You can use this command only if you are an admin user

**_`bot status`_**
   
>Displays the status of the bot

>If on master channel and admin user also it will display info about bots created

**_`create bot on CHANNEL_NAME`_**

>Creates a new bot on the channel specified. 

>slack-smart-bot will create a default rules file specific for your channel. 
You can edit it and add the rules you want. 
As soon as you save the file after editing it will become available on your channel.

>It will work only if you are on Master channel

**_`kill bot on CHANNEL_NAME`_**

>Kills the bot on the specified channel

>Only works if you are on Master channel and you created that bot or you are an admin user

**_`notify MESSAGE`_**

**_`notify all MESSAGE`_**

>It will send a notificaiton message to all bot channels

>It will send a notification message to all channels the bot joined and private conversations with the bot

>Only works if you are on Master channel and you are an admin user


### Available commands only when listening to you or on demand or in a private conversation with the Smart Bot

All the commands described on here or on your specific Rules file can be used when the bot is listening to you or on demand or in a private conversation with the Smart Bot.

For the bot to start listening to you you need to use the "Hi bot" command or one of the aliases

Also you can call any of these commands on demand by using:

**_`!THE_COMMAND`_**

**_`@BOT_NAME THE_COMMAND`_**

**_`BOT_NAME THE_COMMAND`_**

Apart of the specific commands you define on the rules file of the channel, you can use:

**_`ruby RUBY_CODE`_**

**_`code RUBY_CODE`_**

>runs the code supplied and returns the output. Also you can send a Ruby file. Examples:

>code puts (34344/99)*(34+14)

>ruby require 'json'; res=[]; 20.times {res<<rand(100)}; my_json={result: res}; puts my_json.to_json


**_`add shortcut NAME: COMMAND`_**

**_`add shortcut for all NAME: COMMAND`_**

**_`shortchut NAME: COMMAND`_**

**_`shortchut for all NAME: COMMAND`_**

>It will add a shortcut that will execute the command we supply.

>In case we supply 'for all' then the shorcut will be available for everybody

>Example:
>add shortcut for all Spanish account: /code require 'iso/iban'; 10.times {puts ISO::IBAN.random('ES')}

>Then to call this shortcut:

>sc spanish account

>spanish account

>shortcut Spanish Account

**_`delete shortcut NAME`_**

>It will delete the shortcut with the supplied name

**_`see shortcuts`_**

>It will display the shortcuts stored for the user and for :all

**_`id channel CHANNEL_NAME`_**
>shows the id of a channel name

**_`use rules from CHANNEL`_**

**_`use rules CHANNEL`_**

>it will use the rules from the specified channel.

>you need to be part of that channel to be able to use the rules.

**_`stop using rules from CHANNEL`_**

**_`stop using rules CHANNEL`_**

>it will stop using the rules from the specified channel.

### Available commands from channels without a Smart Bot
**_`@BOT_NAME on #CHANNEL_NAME COMMAND`_**

**_`@BOT_NAME #CHANNEL_NAME COMMAND`_**

>It will run the supplied command using the rules on the channel supplied.

>You need to join the specified channel to be able to use those rules.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marioruiz/slack-smart-bot.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

