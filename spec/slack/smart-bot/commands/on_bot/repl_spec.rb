
RSpec.describe SlackSmartBot, "repl" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :user1

    after(:each) do
      send_message "quit", from: user, to: channel
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

    it 'responds continuosly' do
      send_message "!repl", from: user, to: channel
      sleep 1
      send_message "a = 2222", from: user, to: channel
      sleep 1
      expect(buffer(to: channel, from: :ubot).join).to match(/2222/)
      sleep 1
      send_message "a += 3", from: user, to: channel
      sleep 1
      expect(buffer(to: channel, from: :ubot).join).to match(/2225/)
    end

  end
end
