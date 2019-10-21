class SlackSmartBot
  def listen
    @salutations = [config[:nick], "<@#{config[:nick_id]}>", "bot", "smart"]
    @pings = []
    get_bots_created()
    client.on :message do |data|
      unless data.user == "USLACKBOT"
        treat_message(data)
      end
    end

    restarts = 0
    started = false
    while restarts < 200 and !started
      begin
        @logger.info "Bot starting: #{config.inspect}"
        client.start!
      rescue Slack::RealTime::Client::ClientAlreadyStartedError
        @logger.info "ClientAlreadyStarted so we continue with execution"
        started = true
      rescue Exception => e
        started = false
        restarts += 1
        if restarts < 200
          @logger.info "*" * 50
          @logger.fatal "Rescued on starting: #{e.inspect}"
          @logger.info "Waiting 60 seconds to retry. restarts: #{restarts}"
          puts "#{Time.now}: Not able to start client. Waiting 60 seconds to retry: #{config.inspect}"
          sleep 60
        else
          exit!
        end
      end
    end
  end
end
