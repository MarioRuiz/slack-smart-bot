
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
    it "displays error message when channel doesn't exist" do
      send_message "use bot2cuxx", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^The channel you are trying to use doesn't exist/)
    end
    it "displays error message when master channel" do
      send_message "use master_channel", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^You cannot use the rules from Master Channel on any other channel./)
    end
    it "displays error message when no bot running on that channel" do
      send_message "use channel_bot_not_invited", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^There is no bot running on that channel/)
    end
    it "displays error message when trying to use a channel you are not part of" do
      send_message "use bot1cm", from: :user2, to: :cmaster
      sleep 2
      expect(buffer(to: :cmaster, from: :ubot)[-1]).to match(/^You need to join the channel <##{CBOT1CM}> to be able to use the rules/)
    end

    it 'displays message when hi bot' do
      send_message "use bot2cu", from: user, to: channel
      sleep 4
      send_message "Hi bot", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^You are using specific rules for channel: <##{CBOT2CU}>/)
    end
    it 'displays message when bot help' do
      send_message "use bot2cu", from: user, to: channel
      sleep 4
      send_message "bot help", from: user, to: channel
      sleep 3
      expect(buffer(to: channel, from: :ubot).join).to match(/You are using rules from another channel: <##{CBOT2CU}>. These are the specific commands for that channel:/)
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
      expect(buffer(to: :cext1, from: :ubot).join).to match(/I don't understand/)
    end
  end
  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = "use rules from unknown"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      sleep 4
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/I don't understand/)
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/Take in consideration when on external calls/)
  end
  end
end
