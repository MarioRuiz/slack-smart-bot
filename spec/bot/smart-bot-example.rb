require_relative "../../lib/slack-smart-bot"

settings = {
  token: ENV["SSB_TOKEN"], # the API Slack token
  testing: true,
  simulate: true,
  masters: ['marioruizs'],
  master_channel: 'master_channel',
  path: './spec/bot/',
  file: 'smart-bot-example.rb',
  nick: 'example',
  nick_id: 'UMSRCRTAR'
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
