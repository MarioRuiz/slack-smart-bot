
RSpec.describe SlackSmartBot, "notify_message" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :uadmin

    after(:all) do
      sleep 1
      send_message "bye bot", from: user, to: channel
    end

    it "is not possible to be used" do
      send_message "!notify Example", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to eq ""
    end
  end

  describe "on master channel" do
    channel = :cmaster
    user = :uadmin

    after(:all) do
      send_message "bye bot", from: user, to: channel
    end

    it "doesn't allow to be used if not master admin" do
      send_message "!notify example", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot).join).to eq ""
      sleep 1
    end

    it "notifies bots" do
      send_message "notify example", from: user, to: channel
      sleep 1
      expect(buffer(to: :cbot1cm, from: :ubot)[-1]).to eq "example"
      expect(buffer(to: :cbot2cu, from: :ubot)[-1]).to eq "example"
      expect(buffer(to: channel, from: :ubot).join).to match(/Bot channels have been notified/)
    end

    it "accepts on demand" do
      send_message "!notify example", from: user, to: channel
      sleep 1
      expect(buffer(to: :cbot1cm, from: :ubot)[-1]).to eq "example"
      expect(buffer(to: :cbot2cu, from: :ubot)[-1]).to eq "example"
      expect(buffer(to: channel, from: :ubot).join).to match(/Bot channels have been notified/)
    end

    it "notifies specific channel" do
      send_message "notify <##{CBOT1CM}|bot1cm> example", from: user, to: channel
      sleep 1
      expect(buffer(to: :cbot1cm, from: :ubot)[-1]).to eq "example"
      expect(buffer(to: :cext1, from: :ubot)[-1]).to eq "example"
      expect(buffer(to: :cprivext, from: :ubot)[-1]).to eq "example"
      expect(buffer(to: channel, from: :ubot).join).to match(/Bot channel and extended channels have been notified/)
    end
    it "notifies all channels and users" do
      send_message "notify all example", from: user, to: channel
      sleep 3
      expect(buffer(to: :cbot1cm, from: :ubot)[-1]).to eq "example"
      expect(buffer(to: :cext1, from: :ubot)[-1]).to eq "example"
      expect(buffer(to: :cprivext, from: :ubot)[-1]).to eq "example"
      expect(buffer(to: :cexternal, from: :ubot)[-1]).to eq "example"
      expect(buffer(to: DIRECT.user1.ubot, from: :ubot)[-1]).to eq "example"
      expect(buffer(to: channel, from: :ubot).join).to match(/Channels and users have been notified/)
    end
  end

  describe "on direct message" do
    channel = DIRECT.uadmin.ubot
    user = :uadmin

    it "can be called" do
      send_message "notify example", from: user, to: channel
      sleep 3
      expect(bufferc(to: channel, from: :ubot).join).to match(/Bot channels have been notified/)
    end
  end

  describe "on extended channel" do
    it "doesn't respond" do
      send_message "!notify example", from: :uadmin, to: :cext1
      expect(buffer(to: :cext1, from: :ubot).join).to match(/I don't understand/)
    end
  end
  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = "notify example"
      send_message "<@#{UBOT}> on <##{CMASTER}|channel_master> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot, tries: 4).join).to eq ""
    end
  end
end
