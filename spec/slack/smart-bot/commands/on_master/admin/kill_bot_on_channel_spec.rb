
RSpec.describe SlackSmartBot, "kill_bot_on_channel" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :user1
    @regexp_dont_understand = ["what?", "huh?", "sorry?", "what do you mean?", "I don't understand"].join("|")

    after(:all) do
      send_message "bye bot", from: user, to: channel
    end

    it "displays error" do
      send_message "kill bot on external_channel", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Sorry I cannot kill bots from this channel, please visit the master channel/)
    end
  end

  describe "on master channel" do
    channel = :cmaster
    user = :user1

    after(:all) do
      send_message "bye bot", from: user, to: channel
    end
    after(:all) do
      send_message "!kill bot on external_channel", from: user, to: channel
      send_message "bye bot", from: user, to: channel
    end

    it "kills bot on channel name" do
      send_message "create bot on external_channel", from: user, to: channel
      sleep 6
      #expect(buffer(to: :cstatus, from: :ubot).join).to match(/:large_green_circle: The \*SmartBot\* on \*<#CP28CTWSD|external_channel>\* is up and running again./)      
      send_message "kill bot on external_channel", from: user, to: channel
      sleep 3
      expect(buffer(to: :cstatus, from: :ubot).join).to match(/:red_circle: The admin killed SmartBot on \*#external_channel\*/)
      expect(bufferc(to: channel, from: :ubot).join).to match(/Bot on channel: external_channel, has been killed and deleted./)
      send_message "hi bot", from: user, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).to match(/You are on a channel where the SmartBot is just a member/)
    end
    it "kills bot on channel id" do
      send_message "create bot on external_channel", from: user, to: channel
      sleep 6
      send_message "kill bot on <##{CEXTERNAL}|external_channel>", from: user, to: channel
      sleep 3
      expect(bufferc(to: channel, from: :ubot).join).to match(/Bot on channel: external_channel, has been killed and deleted./)
      send_message "hi bot", from: user, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).to match(/You are on a channel where the SmartBot is just a member/)
    end
    it "displays error if not a creator or admin of the channel" do
      send_message "kill bot on bot1cm", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/You need to be the creator or an admin of that bot channel/)
    end
    it "displays error if channel doesn't exist" do
      send_message "kill bot on unknown", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/There is no channel with that name: unknown, please be sure is written exactly the same/)
    end
    it "displays error if channel doesn't have a bot running" do
      send_message "kill bot on external_channel", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/There is no bot in this channel: external_channel/)
    end
    it "can be called on demand" do
      send_message "!kill bot on external_channel", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/There is no bot in this channel: external_channel/)
    end
  end

  describe "on direct message" do
    channel = DIRECT.user1.ubot
    user = :user1

    it "can be called" do
      send_message "kill bot on external_channel", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/There is no bot in this channel: external_channel/)
    end
  end
  describe "on extended channel" do
    it "doesn't respond" do
      send_message "!kill bot on external_channel", from: :uadmin, to: :cext1
      expect(buffer(to: :cext1, from: :ubot).join).to match(/I don't understand/)
    end
  end
  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = "kill bot on unknown"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/#{@regexp_dont_understand}/)
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/Take in consideration when on external calls/)
    end
  end
end
