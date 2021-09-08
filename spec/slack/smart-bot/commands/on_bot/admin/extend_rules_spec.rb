
RSpec.describe SlackSmartBot, "extend_rules" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :uadmin
    @regexp_dont_understand = ["what?", "huh?", "sorry?", "what do you mean?", "I don't understand"].join("|")

    before(:all) do
      send_message "stop using rules on external_channel", from: user, to: channel
    end

    after(:all) do
      send_message "stop using rules on external_channel", from: user, to: channel
      send_message "bye bot", from: user, to: channel
    end

    it "cannot extend rules when not admin" do
      send_message "extend rules to external_channel", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Only admins can extend the rules. Admins on this channel:/)
    end

    it "responds to extend rules to CHANNEL_NAME command" do
      send_message "extend rules to external_channel", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Only admins can extend the rules. Admins on this channel:/)
    end

    it "responds to use rules on CHANNEL_NAME command" do
      send_message "use rules on external_channel", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Only admins can extend the rules. Admins on this channel:/)
    end

    it "responds on demand" do
      send_message "!extend rules to external_channel", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Only admins can extend the rules. Admins on this channel:/)
    end
    it "responds when using CHANNEL_ID" do
      send_message "extend rules to <##{CBOT2CU}|bot2cu>", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/There is a bot already running on that channel./)
    end
    it "doesn't extend when channel doesn't exist" do
      send_message "extend rules to unknown", from: :uadmin, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/The channel you specified doesn't exist/)
    end
    it "doesn't extend when bot running on that channel" do
      send_message "extend rules to bot2cu", from: :uadmin, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/There is a bot already running on that channel./)
    end

    it "doesn't extend when already extended rules on that channel" do
      send_message "extend rules to external_channel", from: :uadmin, to: channel
      sleep 2
      send_message "extend rules to external_channel", from: :uadmin, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/The rules are already extended to that channel./)
    end
    it "doesn't extend when smart bot is not part of the channel" do
      send_message "extend rules to channel_bot_not_invited", from: :uadmin, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/You need to add first to the channel the smart bot user/)
    end
    it "doesn't extend when user is not part of the channel" do
      send_message "extend rules to external_channel_no_user1", from: :user1, to: :cbot2cu
      sleep 2
      expect(buffer(to: :cbot2cu, from: :ubot).join).to match(/You need to join that channel first/)
    end
    it "extends even when other rules are already extended" do
      send_message "stop using rules on external_channel", from: :user1, to: :cbot2cu
      sleep 2
      send_message "extend rules to external_channel", from: user, to: channel
      sleep 2
      send_message "extend rules to external_channel", from: :user1, to: :cbot2cu
      sleep 2
      expect(buffer(to: :cbot2cu, from: :ubot).join).to match(/The rules from channel <##{CBOT1CM}> are already in use on that channel/)
      expect(buffer(to: :cbot2cu, from: :ubot).join).to match(/Now the rules from <##{CBOT2CU}> are available on \*<##{CEXTERNAL}>\*/)
    end
    it "extends the rules if admin" do
      send_message "stop using rules on external_channel", from: user, to: channel
      sleep 2
      send_message "extend rules to external_channel", from: user, to: channel
      sleep 2
      expect(buffer(to: :cmaster, from: :ubot).join).to match(/<@#{UADMIN}> extended the rules from bot1cm to be used on external_channel./)
      expect(buffer(to: :cexternal, from: :ubot).join).to match(/<@#{UADMIN}> extended the rules from <##{CBOT1CM}> to this channel so now you can talk to the Smart Bot on demand using those rules/)
      expect(buffer(to: channel, from: :ubot).join).to match(/Now the rules from <##{CBOT1CM}> are available on \*<##{CEXTERNAL}>\*/)
      send_message "!which rules", from: user, to: :cexternal
      sleep 2
      expect(buffer(to: :cexternal, from: :ubot).join).to match(/bot1cm/)
    end
  end

  describe "on master channel" do
    channel = :cmaster
    user = :uadmin

    after(:all) do
      send_message "bye bot", from: user, to: channel
    end

    it "displays error" do
      send_message "extend rules to external_channel", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/You cannot use the rules from Master Channel on any other channel./)
    end
  end

  describe "on direct message" do
    channel = DIRECT.uadmin.ubot
    user = :uadmin

    it "displays error" do
      send_message "extend rules to external_channel", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/You cannot use the rules from Master Channel on any other channel./)
    end
  end

  describe "on extended channel" do
    after(:all) do
      send_message "stop using rules on external_channel", from: :uadmin, to: :cbot2cu
      sleep 2
      send_message "stop using rules on external_channel", from: :uadmin, to: :cbot1cm
      sleep 2
    end
    it "doesn't respond to extend rules command on extended channel" do
      send_message "!extend rules to unknown", from: :uadmin, to: :cext1
      expect(buffer(to: :cext1, from: :ubot).join).to match(/#{@regexp_dont_understand}/)
    end
    it "run the rules even for user not part of original channel" do
      send_message "!which rules", from: :user2, to: :cext1
      sleep 2
      expect(buffer(to: :cext1, from: :ubot).join).to match(/bot1cm/)
    end

    it "displays don't understand and similar rules for wrong rule" do
      send_message "stop using rules on external_channel", from: :uadmin, to: :cbot2cu
      sleep 2
      send_message "stop using rules on external_channel", from: :uadmin, to: :cbot1cm
      sleep 2
      send_message "extend rules to external_channel", from: :uadmin, to: :cbot1cm
      sleep 2
      send_message "!echox", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).to match(/#{@regexp_dont_understand}/i)
      expect(bufferc(to: :cexternal, from: :ubot).join).to match(/Similar rules on/i)
      send_message "extend rules to external_channel", from: :uadmin, to: :cbot2cu
      sleep 2
      send_message "!doo", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).not_to match(/bot1cm/i)
      expect(bufferc(to: :cexternal, from: :ubot).join).to match(/bot2cu/i)
      send_message "!echox", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).to match(/bot1cm/i)
      expect(bufferc(to: :cexternal, from: :ubot).join).to match(/bot2cu/i)
    end
  end

  describe "on external channel not extended" do
    it "doens't respond to external demand" do
      command = "extend rules to unknown"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      sleep 2
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/#{@regexp_dont_understand}/)
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/Take in consideration when on external calls/)
  end
  end
end
