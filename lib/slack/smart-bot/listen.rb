class SlackSmartBot
  def listen_simulate
    @salutations = [config[:nick], "<@#{config[:nick_id]}>", "bot", "smart", "smartbot", "smart-bot", "smart bot"]
    @pings = []
    @last_activity_check = Time.now
    get_bots_created()
      @buffer_complete = [] unless defined?(@buffer_complete)
      b = File.read("#{config.path}/buffer_complete.log")
      result = b.scan(/^\|(\w+)\|(\w+)\|(\w+)\|([^~]+)~~~/m)
      result.delete(nil)
      new_messages = result[@buffer_complete.size..-1]
      unless new_messages.nil? or new_messages.empty?
        @buffer_complete = result
        new_messages.each do |message|
          channel = message[0].strip
          user = message[1].strip
          user_name = message[2].strip
          command = message[3].to_s.strip
          # take in consideration that on simulation we are treating all messages even those that are not populated on real cases like when the message is not populated to the specific bot connection when message is sent with the bot          
          @logger.info "treat message: #{message}" if config.testing


          if command.match?(/^\s*\-!!/) or command.match?(/^\s*\-\^/)
            command.scan(/`([^`]+)`/).flatten.each do |cmd|
              if cmd.to_s!=''
                cmd = "^#{cmd}"
                treat_message({channel: channel, user: user, text: cmd, user_name: user_name}, false)
              end
            end
          elsif command.match?(/^\s*\-!/)
            command.scan(/`([^`]+)`/).flatten.each do |cmd|
              if cmd.to_s!=''
                cmd = "!#{cmd}"
                treat_message({channel: channel, user: user, text: cmd, user_name: user_name}, false)
              end
            end
          else
            treat_message({channel: channel, user: user, text: command, user_name: user_name})
          end
        end
      end
  end

  def listen
    @pings = []
    @last_activity_check = Time.now
    get_bots_created()

    client.on :message do |data|
      unless data.user == "USLACKBOT" or data.text.nil?
        if data.text.match?(/^\s*\-!!/) or data.text.match?(/^\s*\-\^/)
          data.text.scan(/`([^`]+)`/).flatten.each do |cmd|
            if cmd.to_s!=''
              datao = data.dup
              datao.text = "^#{cmd}"
              treat_message(datao, false)
            end
          end
        elsif data.text.match?(/^\s*\-!/)
          data.text.scan(/`([^`]+)`/).flatten.each do |cmd|
            if cmd.to_s!=''
              datao = data.dup
              datao.text = "!#{cmd}"
              treat_message(datao, false)
            end
          end
        else
          treat_message(data)
        end
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
