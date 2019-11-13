
RSpec.describe SlackSmartBot, "start_bot" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :user1

    after(:all) do
      send_message "bye bot", from: user, to: channel
    end

    it "starts bot with admin user" do
      send_message "start bot", from: :uadmin, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/This bot is running and listening from now on. You can pause again: pause this bot/)
      send_message "hi bot", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).not_to match(/^\s*$/)
      send_message "bot status", from: user, to: channel
      sleep 6
      expect(buffer(to: channel, from: :ubot).join).to match(/Status: on/)
    end

    it "doesn't start with normal user" do
      send_message "start bot", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can change my status/)
    end

    it "accepts 'start this bot'" do
      send_message "start this bot", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can change my status/)
    end

    it "accepts on demand" do
      send_message "!start this bot", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can change my status/)
    end
  end

  describe "on master channel" do
    channel = :cmaster
    user = :user1

    after(:all) do
      send_message "bye bot", from: user, to: channel
    end

    it "can be called" do
      send_message "start this bot", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can change my status/)
    end
  end

  describe "on direct message" do
    channel = DIRECT.user1.ubot
    user = :user1

    it "can be called" do
      send_message "start this bot", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can change my status/)
    end
  end
  describe "on extended channel" do
    it "doesn't respond" do
      send_message "!start this bot", from: :uadmin, to: :cext1
      expect(buffer(to: :cext1, from: :ubot).join).to match(/I don't understand/)
    end
  end
  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = "start this bot"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/I don't understand/)
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/Take in consideration when on external calls/)
    end
  end
end
