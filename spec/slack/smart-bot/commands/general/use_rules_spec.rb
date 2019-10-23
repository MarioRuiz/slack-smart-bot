
RSpec.describe SlackSmartBot, "use_rules" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :user1

    after(:all) do
      send_message "stop using rules from bot2cu", from: user, to: channel
    end

    it "works: use rules from bot2cu" do
      send_message "use rules from bot2cu", from: user, to: channel
      sleep 4
      expect(bufferc(to: channel, from: :ubot).join).to match(/I'm using now the rules from <##{CBOT2CU}>/)
      send_message "!which rules", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/^bot2cu$/)
    end
    it "works: use rules from #bot2cu" do
      send_message "stop using rules from bot2cu", from: user, to: channel
      send_message "use rules from <##{CBOT2CU}|bot2cu>", from: user, to: channel
      sleep 4
      expect(bufferc(to: channel, from: :ubot)[-1]).to match(/I'm using now the rules from <##{CBOT2CU}>/)
      send_message "!which rules", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^bot2cu$/)
    end
    it "works: use rules bot2cu" do
      send_message "stop using rules from bot2cu", from: user, to: channel
      send_message "use rules bot2cu", from: user, to: channel
      sleep 4
      expect(bufferc(to: channel, from: :ubot)[-1]).to match(/I'm using now the rules from <##{CBOT2CU}>/)
      send_message "!which rules", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^bot2cu$/)
    end
    it "works: use bot2cu" do
      send_message "stop using rules from bot2cu", from: user, to: channel
      send_message "use bot2cu", from: user, to: channel
      sleep 4
      expect(bufferc(to: channel, from: :ubot)[-1]).to match(/I'm using now the rules from <##{CBOT2CU}>/)
      send_message "!which rules", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^bot2cu$/)
    end
  end

  describe "on master channel" do
    channel = :cmaster
    user = :user2

    after(:all) do
      send_message "stop using rules from bot2cu", from: user, to: channel
    end

    it "works: use rules from bot2cu" do
      send_message "use rules from bot2cu", from: user, to: channel
      sleep 4
      expect(bufferc(to: channel, from: :ubot).join).to match(/I'm using now the rules from <##{CBOT2CU}>/)
      send_message "!which rules", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^bot2cu$/)
    end
  end

  describe "on direct message" do
    channel = DIRECT.user1.ubot
    user = :user1

    after(:all) do
      send_message "stop using rules from bot2cu", from: user, to: channel
    end

    it "works: use rules from bot2cu" do
      send_message "use rules from bot2cu", from: user, to: channel
      sleep 4
      expect(bufferc(to: channel, from: :ubot).join).to match(/I'm using now the rules from <##{CBOT2CU}>/)
      send_message "!which rules", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^bot2cu$/)
    end
  end
  describe "on extended channel" do
    it "doesn't respond" do
      send_message "!use rules from unknown", from: :uadmin, to: :cext1
      sleep 4
      expect(buffer(to: :cext1, from: :ubot, tries: 4).join).to eq ""
    end
  end
  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = "use rules from unknown"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      sleep 4
      expect(buffer(to: :cexternal, from: :ubot, tries: 4).join).to eq ""
    end
  end
end
