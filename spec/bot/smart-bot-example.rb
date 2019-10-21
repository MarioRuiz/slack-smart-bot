# the channel that will act like the master channel, main channel
MASTER_CHANNEL = "master_channel"
#names of the master users
MASTER_USERS = ["marioruizs"]

require_relative "../../lib/slack-smart-bot"

settings = {
  nick: "example", # the smart bot name
  token: ENV["SSB_TOKEN"], # the API Slack token
  testing: true,
}

SlackSmartBot.new(settings).listen
