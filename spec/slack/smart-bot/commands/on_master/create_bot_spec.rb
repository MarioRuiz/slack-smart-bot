
RSpec.describe SlackSmartBot, "create_bot" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :user1

    before(:all) do
      clean_buffer()
      sleep 1
    end

    after(:all) do
      send_message "bye bot", from: user, to: channel
    end

    it "cannot create bots" do
      send_message "create bot on unknown", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Sorry I cannot create bots from this channel, please visit the master channel/)
    end
  end

  describe "on master channel" do
    channel = :cmaster
    user = :user1

    before(:each) do
      send_message "!kill bot on external_channel", from: user, to: channel
      sleep 1
      clean_buffer()
    end

    after(:all) do
      send_message "!kill bot on external_channel", from: user, to: channel
      send_message "bye bot", from: user, to: channel
    end

    it "responds when not listening" do
      send_message "create bot on unknown", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/There is no channel with that name/)
    end

    it "responds when listening" do
      send_message "hi bot", from: user, to: channel
      send_message "create bot on unknown", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/There is no channel with that name/)
    end

    it "displays error if channel doesn't exist" do
      send_message "hi bot", from: user, to: channel
      send_message "create bot on unknown", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/There is no channel with that name/)
    end

    it "displays error if bot is not member of the channel" do
      send_message "create bot on channel_bot_not_invited", from: :uadmin, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/You need to add first to the channel the smart bot user/)
    end

    it "creates bot on channel name" do
      send_message "create bot on external_channel", from: user, to: channel
      sleep 10
      expect(buffer(to: :cexternal, from: :ubot).join).to match(/Smart Bot started/) unless SIMULATE
      send_message "hi bot", from: user, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).not_to eq ""
      send_message "bot status", from: user, to: :cexternal
      sleep 3
      expect(buffer(to: :cexternal, from: :ubot).join).to match(/Status: on/)
      message = buffer(to: channel, from: :ubot).join
      expect(message).to match(/The bot has been created on channel/)
      expect(message).to match(/Rules file:\s+slack-smart-bot_rules_#{CEXTERNAL}_smartbotuser1.rb/)
      expect(message).to match(/Admins: smartbotuser1, marioruizs/)
    end

    it "creates bot on channel id" do
      send_message "create bot on <##{CEXTERNAL}|external_channel>", from: user, to: channel
      sleep 10
      expect(buffer(to: :cexternal, from: :ubot).join).to match(/Smart Bot started/) unless SIMULATE
      send_message "hi bot", from: user, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).not_to eq ""
      send_message "bot status", from: user, to: :cexternal
      sleep 3
      expect(buffer(to: :cexternal, from: :ubot).join).to match(/Status: on/)
      message = buffer(to: channel, from: :ubot).join
      expect(message).to match(/The bot has been created on channel/)
      expect(message).to match(/Rules file:\s+slack-smart-bot_rules_#{CEXTERNAL}_smartbotuser1.rb/)
      expect(message).to match(/Admins: smartbotuser1, marioruizs/)
    end

    it "cannot create a bot if a bot is already running on channel" do
      send_message "create bot on external_channel", from: user, to: channel
      sleep 3
      send_message "create bot on external_channel", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/There is already a bot in this channel/)
    end

    it "creates a cloud bot" do
      send_message "create cloud bot on external_channel", from: user, to: channel
      message = buffer(to: channel, from: :ubot).join
      expect(message).to match(/The bot has been created on channel/)
      expect(message).to match(/Copy the bot folder to your cloud location and run/)
      sleep 3
      expect(buffer(to: :cexternal, from: :ubot).join).not_to match(/Smart Bot started/)
    end
  end

  describe "on direct message" do
    channel = DIRECT.user1.ubot
    user = :user1

    it "can create bot" do
      send_message "create bot on unknown", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/There is no channel with that name/)
    end
  end

  describe "on extended channel" do
    it "doesn't respond" do
      send_message "!create bot on unknown", from: :uadmin, to: :cext1
      expect(buffer(to: :cext1, from: :ubot).join).to match(/I don't understand/)
    end
  end
  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = "create bot on unknown"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/I don't understand/)
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/Take in consideration when on external calls/)
    end
  end
end
