# the channel that will act like the master channel, main channel
MASTER_CHANNEL = "master_channel"
#names of the master users
MASTER_USERS = ["marioruizs"]

require_relative "../../lib/slack-smart-bot"

settings = {
  nick: "example", # the smart bot name
  token: ENV["SSB_TOKEN"], # the API Slack token
  testing: true,
  simulate: true
}

if settings.simulate 
  sb = SlackSmartBot.new(settings)
  while true do
    sb.listen_simulate()
    sleep 0.2
  end
else
  SlackSmartBot.new(settings).listen
end
