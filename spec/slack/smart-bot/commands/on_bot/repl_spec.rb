
RSpec.describe SlackSmartBot, "repl" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :user1

    after(:each) do
      send_message "quit", from: user, to: channel
      send_message "quit", from: :user2, to: channel
    end

    after(:all) do
      send_message "bye bot", from: user, to: channel
    end

    it 'starts a repl with repl command' do
      send_message "!repl", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Session name: \*\w+_\d+\*/)
    end
    it 'starts a repl with irb command' do
      send_message "!irb", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Session name: \*\w+_\d+\*/)
    end
    it 'starts a repl with live command' do
      send_message "!live", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Session name: \*\w+_\d+\*/)
    end

    it "generates a repl session name if not supplied" do
      send_message "!repl", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Session name: \*\w+_\d+\*/)
    end

    it "uses the repl session name if supplied" do
      send_message "!repl example", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Session name: \*example/)
    end

    it "generates a new session name when already exists" do
      send_message "!repl example", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Session name: \*example\d+\*/)
    end

    it 'ends the session when sending quit' do
      send_message "!repl", from: user, to: channel
      send_message "quit", from: user, to: channel
      sleep 0.5 if SIMULATE

      expect(buffer(to: channel, from: :ubot).join).to match(/REPL session finished: \w+_\d+/)
    end
    it 'ends the session when sending exit' do
      send_message "!repl", from: user, to: channel
      send_message "exit", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/REPL session finished: \w+_\d+/)
    end
    it 'ends the session when sending exit' do
      send_message "!repl", from: user, to: channel
      send_message "bye", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/REPL session finished: \w+_\d+/)
    end
    #todo: This test is not running on travis but locally. Investigate the reason
    it 'executes the .smart-bot-repl file', :avoid_travis do
      send_message "!repl prerun ", from: user, to: channel
      send_message "puts LOLO", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/beautiful/i)
    end
    it 'creates repls with option clean' do
      send_message "!clean repl", from: user, to: channel
      send_message "puts LOLO", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).not_to match(/beautiful/i)
    end

    #todo: This test is not running on travis but locally. Investigate the reason
    it 'responds continuosly', :avoid_travis do
      send_message "!repl", from: user, to: channel
      send_message "a = 2222", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/2222/)
      send_message "a += 3", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/2225/)
    end

    it "doesn't allow to add collaborator if on another repl" do
      send_message "!repl", from: user, to: channel
      send_message "!repl", from: :user2, to: channel
      send_message "add collaborator <@#{USER2}>", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match("Sorry, <@#{USER2}> is already in a repl. Please ask her/him to quit it first")
    end

    it "adds collaborator" do
      send_message "!repl", from: user, to: channel
      send_message "add collaborator <@#{USER2}>", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match("Collaborator added. Now <@#{USER2}> can interact with this repl.")
      send_message "a = 3 + 97", from: user, to: channel
      sleep 1
      clean_buffer()
      send_message "puts a", from: :user2, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/100/)
    end

    it "removes collaborator" do
      send_message "!repl", from: user, to: channel
      send_message "add collaborator <@#{USER2}>", from: user, to: channel
      send_message "quit", from: :user2, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match("Collaborator <@#{USER2}> removed.")
      send_message "a = 3 + 97", from: user, to: channel
      sleep 1
      clean_buffer()
      send_message "puts a", from: :user2, to: channel
      expect(buffer(to: channel, from: :ubot).join).not_to match(/100/)
    end

    it "removes session and collaborator when creator quitting" do
      send_message "!repl", from: user, to: channel
      send_message "add collaborator <@#{USER2}>", from: user, to: channel
      send_message "quit", from: user, to: channel
      clean_buffer()
      send_message "puts 'love'", from: :user2, to: channel
      expect(buffer(to: channel, from: :ubot).join).to be_empty
      send_message "puts 'love'", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to be_empty
    end
  end
end
