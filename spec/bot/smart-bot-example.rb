require_relative "../../lib/slack-smart-bot"
require_relative "./environment.rb" if File.exist?("./spec/bot/environment.rb") or File.exist?("./environment.rb")

settings = {
  token: ENV["SSB_TOKEN"], # the API Slack token
  user_token: ENV["SLACK_USER_TOKEN"],
  granular_token: ENV["SLACK_GRANULAR_TOKEN"],
  testing: true,
  masters: ["marioruizs"],
  master_channel: "master_channel",
  stats: true,
  file: "smart-bot-example.rb",
  nick: "example", #for testing purposes
  nick_id: "UMSRCRTAR", #for testing purposes
  logrtm: false,
  public_holidays: {
    api_key: ENV["CALENDARIFIC_API_KEY"],
    default_calendar: "iceland",
  },
  ai: {
    open_ai: {
      testing: true,
      models: {
        host: ENV["OPENAI_LLM_HOST"],
        access_token: ENV["OPENAI_LLM_API_KEY"],
        url: "/model/info"
      },
      chat_gpt: {
        host: ENV["OPENAI_LLM_HOST"],
        access_token: ENV["OPENAI_LLM_API_KEY"],
        model: "gpt-35-turbo",
        smartbot_model: "gpt-4-32k",
      },
    },
  },
  recover_encrypted: true,
  encrypt: false,
  github: { token: ENV["GITHUB_TOKEN"] }, #,
#jira: {host: ENV['JIRA_HOST'], user: 'smartbot', password: ENV['JIRA_PASSWORD']}
}

settings.ai.open_ai = { access_token: ENV["OPENAI_ACCESS_TOKEN"] } if ENV["OPENAI_HOST"].to_s == "true"

if ENV["SIMULATE"] == "true"
  if ENV["OPENAI_HOST"].to_s == "true"
    settings.encrypt = true
    settings.ai.open_ai = { access_token: ENV["OPENAI_ACCESS_TOKEN"] }
  else
    settings.encrypt = false
  end
  settings.simulate = true
  settings.path = "./spec/bot/"
  require_relative "client.rb"
  settings.client = csettings.client
  puts "SIMULATING..."
  puts "settings: #{settings.inspect} "
  sb = SlackSmartBot.new(settings)
  while sb.config.simulate
    sb.listen_simulate()
    sleep 0.2
  end
else
  settings.simulate = false
  SlackSmartBot.new(settings).listen
end
