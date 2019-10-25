class SlackSmartBot
  def listen_simulate
    @salutations = [config[:nick], "<@#{config[:nick_id]}>", "bot", "smart"]
    @pings = []
    get_bots_created()
      @buffer_complete = [] unless defined?(@buffer_complete)
      b = File.read("#{config.path}/buffer_complete.log")
      result = b.scan(/^\|(\w+)\|(\w+)\|([^$]+)\$\$\$/m)
      result.delete(nil)
      new_messages = result[@buffer_complete.size..-1]
      unless new_messages.nil? or new_messages.empty?
        @buffer_complete = result
        new_messages.each do |message|
          channel = message[0].strip
          user = message[1].strip
          command = message[2].to_s.strip
          # take in consideration that on simulation we are treating all messages even those that are not populated on real cases like when the message is not populated to the specific bot connection when message is sent with the bot
          @logger.info "treat message: #{message}" if config.testing
          treat_message({channel: channel, user: user, text: command})
        end
      end
  end

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
