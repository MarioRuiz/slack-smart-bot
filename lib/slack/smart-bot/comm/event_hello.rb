class SlackSmartBot
  def event_hello()

    if config.on_master_bot
      File.open("#{config.path}/status/version.txt", 'w') {|f| f.write(VERSION) }
    end

    @first_time_bot_started ||= true
    unless config.simulate
      m = "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."
      puts m
      save_status :on, :connected, m

      @logger.info m
      config.nick = client.self.name
      config.nick_id = client.self.id
      if config.granular_token.empty?
        config.nick_granular = ""
        config.nick_id_granular = ""
      else
        conn_granular = NiceHttp.new(host: "https://slack.com", log: :no)
        conn_granular.headers = { authorization: "Bearer #{config.granular_token}" }
        resp = conn_granular.get("/api/auth.test")
        if resp.code.to_s == '200' and resp.body.json(:ok) == true
          config.nick_granular = resp.body.json(:user)
          config.nick_id_granular = resp.body.json(:user_id)
        else
          config.nick_granular = ""
          config.nick_id_granular = ""
        end
        conn_granular.close
      end
      if client.team.key?(:enterprise_id)
        config.team_id = client.team.enterprise_id
        config.team_name = client.team.enterprise_name
      else
        config.team_id = client.team.id
        config.team_name = client.team.name
      end
      config.team_domain = client.team.domain
    end
    @salutations = [config[:nick], "<@#{config[:nick_id]}>", "@#{config[:nick]}", "bot", "smart", "smartbot", "smart-bot", "smart bot"]

    gems_remote = `gem list slack-smart-bot --remote`
    version_remote = gems_remote.to_s().scan(/slack-smart-bot \((\d+\.\d+\.\d+)/).join
    version_message = ""
    if Gem::Version.new(version_remote) > Gem::Version.new(VERSION)
      version_message = ". There is a new available version: #{version_remote}."
    end
    if (!config[:silent] or ENV['BOT_SILENT'].to_s == 'false') and !config.simulate
      unless ENV['BOT_SILENT']=='true' or !@first_time_bot_started
        respond "Smart Bot started v#{VERSION}#{version_message}\nIf you want to know what I can do for you: `bot help`.\n`bot rules` if you want to display just the specific rules of this channel.\nYou can talk to me privately if you prefer it."
      end
      ENV['BOT_SILENT'] = 'true' if config[:silent] and ENV['BOT_SILENT'].to_s != 'true'
    end
    @routines.each do |ch, rout|
      rout.each do |k, v|
        if !v[:running] and v[:channel_name] == config.channel
          create_routine_thread(k, v)
        end
      end
    end
    @first_time_bot_started = false
  end
end
