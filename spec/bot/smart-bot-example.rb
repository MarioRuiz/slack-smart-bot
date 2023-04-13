require_relative "../../lib/slack-smart-bot"
require_relative './environment.rb' if File.exist?('./spec/bot/environment.rb') or File.exist?('./environment.rb')

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
  public_holidays: {
    api_key: ENV['CALENDARIFIC_API_KEY'],
    default_calendar: 'iceland'
  },
  ai: {
    open_ai: {
      access_token: ENV['OPENAI_ACCESS_TOKEN'],
      organization_id: ENV['OPENAI_ORGANIZATION_ID']
    }
  },
  encrypt: true,
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
