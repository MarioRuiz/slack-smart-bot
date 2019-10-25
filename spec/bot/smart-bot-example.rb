require_relative "../../lib/slack-smart-bot"

settings = {
  nick: "example", # the smart bot name
  token: ENV["SSB_TOKEN"], # the API Slack token
  testing: true,
  simulate: true,
  masters: ['marioruizs'],
  master_channel: 'master_channel',
  path: './spec/bot/',
  file: 'smart-bot-example.rb'
}

if settings.simulate 
  sb = SlackSmartBot.new(settings)
  while sb.config.simulate do
    sb.listen_simulate()
    sleep 0.2
  end
else
  SlackSmartBot.new(settings).listen
end
