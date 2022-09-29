require_relative "../../lib/slack-smart-bot"

settings = {
  token: ENV["SSB_TOKEN"], # the API Slack token
  user_token: ENV['SLACK_USER_TOKEN'],
  testing: true,
  masters: ['marioruizs'],
  master_channel: 'master_channel',
  stats: true,
  file: 'smart-bot-example.rb',
  nick: 'example', 
  nick_id: 'UMSRCRTAR',
  logrtm: false,
  github: {token: ENV['GITHUB_TOKEN']}#,
  #jira: {host: ENV['JIRA_HOST'], user: 'smartbot', password: ENV['JIRA_PASSWORD']}
}

if ENV['SIMULATE'] == 'true'
  settings.simulate = true
  settings.path = './spec/bot/'
  require_relative 'client.rb'
  settings.client = csettings.client
  sb = SlackSmartBot.new(settings)
  while sb.config.simulate do
    sb.listen_simulate()
    sleep 0.2
  end
else
  settings.simulate = false
  SlackSmartBot.new(settings).listen
end
