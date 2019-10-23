
RSpec.describe SlackSmartBot, "exit_bot" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :uadmin

    after(:each) do
      sleep 1
      send_message "bye bot", from: user, to: channel
    end

    it "is not possible to be used" do
      send_message "!exit bot", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/To do this you need to be an admin user in the master channel/)
    end
  end

  describe "on master channel" do
    channel = :cmaster
    user = :uadmin

    after(:each) do
      send_message "bye bot", from: user, to: channel
    end

    it "doesn't allow to be used if not master admin" do
      send_message "!exit bot", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to eq "Only admin users can kill me"
    end

    it "responds to 'quit'" do
      send_message "quit bot", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to eq "Only admin users can kill me"
    end

    it "responds to 'close'" do
      send_message "close bot", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to eq "Only admin users can kill me"
    end
    it "can be cancelled" do
      send_message "close bot", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/are you sure\?/)
      send_message "no", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to eq "Thanks, I'm happy to be alive"
    end
  end

  describe "on direct message" do
    channel = DIRECT.user1.ubot
    user = :user1

    it "can be called" do
      send_message "close bot", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot)[-1]).to eq "Only admin users can kill me"
    end
  end

  describe "on extended channel" do
    it "doesn't respond" do
      send_message "!close bot", from: :uadmin, to: :cext1
      expect(buffer(to: :cext1, from: :ubot, tries: 4).join).to eq ""
    end
  end
  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = "close bot"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot, tries: 4).join).to eq ""
    end
  end
end
