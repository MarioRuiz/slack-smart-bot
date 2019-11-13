
RSpec.describe SlackSmartBot, "stop_using_rules_on" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :uadmin

    before(:all) do
      send_message "extend rules to external_channel", from: user, to: channel
    end
    after(:all) do
      send_message "stop using rules on external_channel", from: user, to: channel
      send_message "bye bot", from: user, to: channel
    end

    it "cannot stop using rules when not admin" do
      send_message "stop using rules on external_channel", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Only admins can extend or stop using the rules/)
    end

    it "responds to stop using rules on CHANNEL_NAME command" do
      send_message "stop using rules on external_channel", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Only admins can extend or stop using the rules/)
    end

    it "responds on demand" do
      send_message "!stop using rules on external_channel", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Only admins can extend or stop using the rules/)
    end
    it "responds when using CHANNEL_ID" do
      send_message "stop using rules on <##{CBOT2CU}|bot2cu>", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Only admins can extend or stop using the rules/)
    end
    it "doesn't stop using rules when no extended rules on channel" do
      send_message "stop using rules on unknown", from: :uadmin, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/The rules were not accessible from \*unknown\*/)
    end

    it "stops using the rules if admin" do
      send_message "stop using rules on external_channel", from: user, to: channel
      sleep 2
      expect(buffer(to: :cmaster, from: :ubot).join).to match(/<@#{UADMIN}> removed the access to the rules of bot1cm from external_channel/)
      expect(buffer(to: :cexternal, from: :ubot).join).to match(/<@#{UADMIN}> removed the access to the rules of <##{CBOT1CM}> from this channel./)
      expect(buffer(to: channel, from: :ubot).join).to match(/The rules won't be accessible from \*<##{CEXTERNAL}>\* from now on/)
      send_message "!which rules", from: user, to: :cexternal
      sleep 2
      expect(buffer(to: :cexternal, from: :ubot).join).not_to match(/bot1cm/)
    end
  end
  describe "on extended channel" do
    it "doesn't respond" do
      send_message "!stop using rules on unknown", from: :uadmin, to: :cext1
      expect(buffer(to: :cext1, from: :ubot).join).to match(/I don't understand/)
    end
  end

  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = "stop using rules on unknown"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/I don't understand/)
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/Take in consideration when on external calls/)
    end
  end
end
