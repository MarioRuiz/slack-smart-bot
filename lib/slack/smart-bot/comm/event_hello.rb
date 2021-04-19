class SlackSmartBot
  def event_hello()
    unless config.simulate
      m = "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."
      puts m
      @logger.info m
      config.nick = client.self.name
      config.nick_id = client.self.id
    end
    @salutations = [config[:nick], "<@#{config[:nick_id]}>", "bot", "smart"]

    gems_remote = `gem list slack-smart-bot --remote`
    version_remote = gems_remote.to_s().scan(/slack-smart-bot \((\d+\.\d+\.\d+)/).join
    version_message = ""
    if Gem::Version.new(version_remote) > Gem::Version.new(VERSION)
      version_message = ". There is a new available version: #{version_remote}."
    end
    if (!config[:silent] or ENV['BOT_SILENT'].to_s == 'false') and !config.simulate
      ENV['BOT_SILENT'] = 'true' if config[:silent] and ENV['BOT_SILENT'].to_s != 'true'
      respond "Smart Bot started v#{VERSION}#{version_message}\nIf you want to know what I can do for you: `bot help`.\n`bot rules` if you want to display just the specific rules of this channel.\nYou can talk to me privately if you prefer it."
    end
    @routines.each do |ch, rout|
      rout.each do |k, v|
        if !v[:running] and v[:channel_name] == config.channel
          create_routine_thread(k)
        end
      end
    end
  end
end