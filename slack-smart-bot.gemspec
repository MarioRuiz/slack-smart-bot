Gem::Specification.new do |s|
  s.name        = 'slack-smart-bot'
  s.version     = '0.6.16'
  s.summary     = "Create a Slack bot that is smart and so easy to expand, create new bots on demand, run ruby code on chat, create shortcuts..."
  s.description = "Create a Slack bot that is smart and so easy to expand, create new bots on demand, run ruby code on chat, create shortcuts... 
  The main scope of this gem is to be used internally in the company so teams can create team channels with their own bot to help them on their daily work, almost everything is suitable to be automated!! 
  slack-smart-bot can create bots on demand, create shortcuts, run ruby code... just on a chat channel. 
  You can access it just from your mobile phone if you want and run those tests you forgot to run, get the results, restart a server... no limits."
  s.authors     = ["Mario Ruiz"]
  s.email       = 'marioruizs@gmail.com'
  s.files       = ["lib/slack-smart-bot.rb","lib/slack-smart-bot_rules.rb","LICENSE","README.md",".yardopts"]
  s.extra_rdoc_files = ["LICENSE","README.md"]
  s.homepage    = 'https://github.com/MarioRuiz/slack-smart-bot'
  s.license       = 'MIT'
  s.add_runtime_dependency 'slack-ruby-client', '~> 0.14', '>= 0.14.4'
  s.add_runtime_dependency 'celluloid-io', '~> 0.17', '>= 0.17.3'
  s.required_ruby_version = '>= 2.4'
  s.post_install_message = "Thanks for installing! Visit us on https://github.com/MarioRuiz/slack-smart-bot"
end