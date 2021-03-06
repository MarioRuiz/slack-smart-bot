
RSpec.describe SlackSmartBot, "start_routine" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :uadmin
    before(:all) do
      send_message "delete routine example", from: user, to: channel
      sleep 2
      send_message "add routine example every 2s !ruby puts 'Sam'", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Added routine \*`example`\* to the channel/)
      sleep 2
    end

    after(:all) do
      sleep 1
      send_message "delete routine example", from: user, to: channel
    end

    it "starts the routine if admin user" do
      send_message "pause routine example", from: user, to: channel
      sleep 2
      expect(bufferc(to: channel, from: :ubot).join).to match(/The routine \*`example`\* has been paused/)
      send_message "start routine example", from: user, to: channel
      sleep 3
      expect(buffer(to: channel, from: :ubot).join).to match(/has been started. The change will take effect in less than 30 secs/)
      times = 0
      while !buffer(to: channel, from: :ubot).join.match?(/routine \*`example`\*: !ruby puts 'Sam'/) and times < 30
        times += 1
        sleep 1
      end
      expect(buffer(to: channel, from: :ubot).join).to match(/routine \*`example`\*: !ruby puts 'Sam'/)
    end

    it "accepts on demand" do
      send_message "!start routine example", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).not_to eq("")
    end

    it "doesn't allow to start routine if not admin" do
      sleep 1
      send_message "start routine example", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Only admin users can use this command/)
    end
  end

  describe "on master channel" do
    channel = :cmaster
    user = :user1

    after(:all) do
      send_message "bye bot", from: user, to: channel
    end

    it "can be called" do
      send_message "start routine example", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can use this command/)
    end
  end

  describe "on direct message" do
    channel = DIRECT.user1.ubot
    user = :user1

    it "can be called" do
      send_message "start routine example", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can use this command/)
    end
  end

  describe "on extended channel" do
    it "doesn't respond" do
      send_message "!start routine example", from: :uadmin, to: :cext1
      expect(buffer(to: :cext1, from: :ubot).join).to match(/I don't understand/)
    end
  end
  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = "start routine example"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/I don't understand/)
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/Take in consideration when on external calls/)
    end
  end
end
