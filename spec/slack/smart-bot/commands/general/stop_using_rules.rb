
RSpec.describe SlackSmartBot, "stop_using_rules" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :user1

    before(:each) do
      send_message "use rules from bot2cu", from: user, to: channel
    end

    after(:all) do
      send_message "stop using rules from bot2cu", from: user, to: channel
    end

    it "works: stop using rules from bot2cu" do
      send_message "stop using rules from bot2cu", from: user, to: channel
      sleep 1
      expect(bufferc(to: channel, from: :ubot).join).to match(/You won't be using those rules from now on/)
      send_message "!which rules", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/^bot1cm$/)
    end
    it "works: stop using rules from #bot2cu" do
      send_message "stop using rules from <##{CBOT2CU}|bot2cu>", from: user, to: channel
      sleep 1
      expect(bufferc(to: channel, from: :ubot).join).to match(/You won't be using those rules from now on/)
      send_message "!which rules", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/^bot1cm$/)
    end
    it "displays message when no using those rules" do
      send_message "stop using rules from master_channel", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/You are not using those rules/)
      sleep 1
      send_message "stop using rules from bot2cu", from: user, to: channel
      sleep 1
      send_message "stop using rules from bot2cu", from: user, to: channel
      sleep 1
      expect(buffer(to: channel, from: :ubot).join).to match(/You were not using those rules/)
    end
  end

  describe "on master channel" do
    channel = :cmaster
    user = :user2

    before(:each) do
      send_message "use rules from bot2cu", from: user, to: channel
    end

    after(:all) do
      send_message "stop using rules from bot2cu", from: user, to: channel
    end

    it "works: stop using rules from bot2cu" do
      send_message "stop using rules from bot2cu", from: user, to: channel
      sleep 1
      expect(bufferc(to: channel, from: :ubot).join).to match(/You won't be using those rules from now on/)
      send_message "!which rules", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/^master_channel$/)
    end
  end

  describe "on direct message" do
    channel = DIRECT.user1.ubot
    user = :user1

    before(:each) do
      send_message "use rules from bot2cu", from: user, to: channel
    end

    after(:all) do
      send_message "stop using rules from bot2cu", from: user, to: channel
    end

    it "works: stop using rules from bot2cu" do
      send_message "stop using rules from bot2cu", from: user, to: channel
      sleep 1
      expect(bufferc(to: channel, from: :ubot).join).to match(/You won't be using those rules from now on/)
      send_message "!which rules", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/I don't understand/)
    end

    it "displays message when no using those rules" do
      send_message "stop using rules from master_channel", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/You are not using those rules/)
    end

  end

  describe "on extended channel" do
    it "doesn't respond" do
      send_message "!stop using rules from unknown", from: :uadmin, to: :cext1
      expect(buffer(to: :cext1, from: :ubot, tries: 4).join).to eq ""
    end
  end

  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = "stop using rules from unknown"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot, tries: 4).join).to eq ""
    end
  end
end
