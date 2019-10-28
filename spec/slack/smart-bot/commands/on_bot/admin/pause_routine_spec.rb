
RSpec.describe SlackSmartBot, "pause_routine" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :uadmin

    after(:all) do
      sleep 1
      send_message "delete routine example", from: user, to: channel
    end

    it "pauses the routine if admin user" do
      send_message "add routine example every 2s !ruby puts 'Sam'", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Added routine \*`example`\* to the channel/)
      sleep 2
      send_message "pause routine example", from: user, to: channel
      sleep 2
      expect(bufferc(to: channel, from: :ubot).join).to match(/The routine \*`example`\* has been paused/)
      sleep 3
      expect(buffer(to: channel, from: :ubot).join).to eq ""
    end

    it "accepts on demand" do
      send_message "!pause routine example", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).not_to eq ""
    end

    it "doesn't allow to pause routine if not admin" do
      send_message "pause routine example", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Only admin users can use this command/)
    end

    it "verifies name of routine exists" do
      send_message "pause routine examplexx", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/There isn't a routine with that name/)
    end

  end

  describe "on master channel" do
    channel = :cmaster
    user = :user1

    after(:all) do
      send_message "bye bot", from: user, to: channel
    end

    it "can be called" do
      send_message "pause routine example", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can use this command/)
    end
  end

  describe "on direct message" do
    channel = DIRECT.user1.ubot
    user = :user1

    it "can be called" do
      send_message "pause routine example", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can use this command/)
    end
  end

  describe "on extended channel" do
    it "doesn't respond" do
      send_message "!pause routine example", from: :uadmin, to: :cext1
      expect(buffer(to: :cext1, from: :ubot, tries: 4).join).to eq ""
    end
  end
  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = "pause routine example"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot, tries: 4).join).to eq ""
    end
  end
end
