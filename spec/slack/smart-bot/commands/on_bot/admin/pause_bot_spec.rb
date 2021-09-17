
RSpec.describe SlackSmartBot, "pause_bot" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :user1

    after(:all) do
      send_message "start this bot", from: :uadmin, to: channel
      send_message "bye bot", from: user, to: channel
    end

    it "pause bot with admin user" do
      send_message "pause bot", from: :uadmin, to: channel
      expect(buffer(to: :cstatus, from: :ubot).join).to match(/:red_circle: The admin paused this bot \*<#CN0595D50|bot1cm>\*/)
      expect(bufferc(to: channel, from: :ubot).join).to match(/This bot is paused from now on. You can start it again: start this bot/)
      send_message "hi bot", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/^\s*$/)
      send_message "bot status", from: user, to: channel
      sleep 6
      expect(buffer(to: channel, from: :ubot).join).to match(/Status: paused/)
    end

    it 'displays error if trying to use rules from a paused bot' do
      send_message "pause bot", from: :uadmin, to: channel
      sleep 2
      send_message "use bot1cm", from: user, to: :cmaster
      sleep 2
      expect(buffer(to: :cmaster, from: :ubot)[-1]).to match(/^The bot in that channel is not :on/)
    end

    it "doesn't pause with normal user" do
      send_message "pause bot", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can put me on pause/)
    end

    it "accepts 'pause this bot'" do
      send_message "pause this bot", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can put me on pause/)
    end

    it "accepts on demand" do
      send_message "!pause this bot", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can put me on pause/)
    end
  end

  describe "on master channel" do
    channel = :cmaster
    user = :user1

    after(:all) do
      send_message "start this bot", from: :uadmin, to: channel
      send_message "bye bot", from: user, to: channel
    end

    it "can be called" do
      send_message "pause this bot", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can put me on pause/)
    end
  end

  describe "on direct message" do
    channel = DIRECT.user1.ubot
    user = :user1

    it "can be called" do
      send_message "pause this bot", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can put me on pause/)
    end
  end

  describe "on extended channel" do
    it "doesn't respond" do
      send_message "!pause this bot", from: :uadmin, to: :cext1
      expect(buffer(to: :cext1, from: :ubot).join).to match(/I don't understand/)
    end
  end
  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = "pause this bot"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/I don't understand/)
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/Take in consideration when on external calls/)
  end
  end
end
