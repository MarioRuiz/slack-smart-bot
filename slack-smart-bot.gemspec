Gem::Specification.new do |s|
  s.name = "slack-smart-bot"
  s.version = "1.15.25"
  s.summary = "Create a Slack bot that is smart and so easy to expand, create new bots on demand, run ruby code on chat, create shortcuts, chatGPT, DALL-E, Whisper ..."
  s.description = "Create a Slack bot that is smart and so easy to expand, create new bots on demand, run ruby code on chat, create shortcuts, chatGPT, DALL-E, Whisper...
  The main scope of this gem is to be used internally in the company so teams can create team channels with their own bot to help them on their daily work, almost everything is suitable to be automated!!
  slack-smart-bot can create bots on demand, create shortcuts, run ruby code, use chatGPT, DALL-E or Whisper... just on a chat channel.
  You can access it just from your mobile phone if you want and run those tests you forgot to run, get the results, restart a server, or have a chatGPT session... no limits."
  s.authors = ["Mario Ruiz"]
  s.email = "marioruizs@gmail.com"
  s.files = Dir["lib/slack/smart-bot/**/*.rb"] + Dir["img/**"] + ["lib/slack-smart-bot.rb", "lib/slack-smart-bot_rules.rb", "lib/slack-smart-bot_general_rules.rb", "lib/slack-smart-bot_general_commands.rb", "LICENSE", "README.md", ".yardopts", "whats_new.txt"]
  s.extra_rdoc_files = ["LICENSE", "README.md"]
  s.homepage = "https://github.com/MarioRuiz/slack-smart-bot"
  s.license = "MIT"
  s.add_runtime_dependency "slack-ruby-client", "~> 2", ">= 2.3.0"
  s.add_runtime_dependency "nice_http", "~> 1.9"
  s.add_runtime_dependency "method_source", "~> 1.0"
  s.add_runtime_dependency "ruby-openai", "~> 6", ">= 6.3.1"
  s.add_runtime_dependency "net-ldap", "~> 0.19", ">= 0.19.0"
  s.add_runtime_dependency "nice_hash", "~> 1", ">= 1.18.7"
  s.add_runtime_dependency "string_pattern", "~> 2", ">=2.2.3"
  s.add_runtime_dependency "async-websocket", "~> 0.8.0"
  s.add_runtime_dependency "amazing_print", "~> 1", ">= 1.4.0"
  s.add_runtime_dependency "openssl", "~> 3"
  s.add_runtime_dependency "nokogiri", "~> 1"
  s.add_runtime_dependency "tzinfo", "~> 1"
  s.add_runtime_dependency "pdf-reader", "~> 2.12"
  s.add_runtime_dependency "docx", "~> 0.8"
  #s.add_runtime_dependency "tiktoken_ruby", "~> 0.0.9"
  s.add_runtime_dependency "tiktoken_ruby", "~> 0.0.7" #jal todo: fixed value since version 0.0.8 and 0.0.9 failed to install on SmartBot VM. Revert when fixed.
  s.add_runtime_dependency "engtagger", "~> 0.4"
  s.add_development_dependency "rspec", "~> 3.9"
  s.required_ruby_version = ">= 2.7.3" #due to this bug on Ruby 2.7 console gem: https://github.com/socketry/console/issues/37
  s.post_install_message = "Thanks for installing! Visit us on https://github.com/MarioRuiz/slack-smart-bot"
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
end
