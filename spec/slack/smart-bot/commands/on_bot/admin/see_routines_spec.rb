
RSpec.describe SlackSmartBot, "see_routines" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :uadmin

    before(:all) do
      sleep 1
      send_message "add routine example at 00:00 !ruby puts 'Sam'", from: user, to: channel
    end

    after(:all) do
      sleep 1
      send_message "delete routine example", from: user, to: channel
    end

    it "displays the routines if admin user" do
      send_message "see routines", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/Routines on channel \*bot1cm\*/)
      expect(buffer(to: channel, from: :ubot).join).to match(/`*example*`/)
      expect(buffer(to: channel, from: :ubot).join).to match(/Status: on/)
    end

    it "displays warning for 'see all routines'" do
      send_message "see all routines", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/To see all routines on all channels you need to run the command on the master channel./)
      expect(buffer(to: channel, from: :ubot).join).to match(/I'll display only the routines on this channel./)
      expect(buffer(to: channel, from: :ubot).join).to match(/Routines on channel \*bot1cm\*/)
      expect(buffer(to: channel, from: :ubot).join).to match(/`*example*`/)
      expect(buffer(to: channel, from: :ubot).join).to match(/Status: on/)
    end

    it "accepts on demand" do
      send_message "!see routines", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).not_to eq("")
      sleep 1
    end

    it "doesn't allow to see routines if not admin" do
      sleep 1
      send_message "see routines", from: :user1, to: channel
      sleep 1
      expect(buffer(to: channel, from: :ubot).join).to match(/Only admin users can use this command/)
    end
  end

  describe "on master channel" do
    channel = :cmaster
    user = :user1

    after(:all) do
      send_message "delete routine example", from: user, to: :cbot1cm
      send_message "bye bot", from: user, to: channel
    end

    it "can be called" do
      send_message "see routines", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can use this command/)
    end

    it "displays routines for 'see all routines'" do
      send_message "add routine example at 00:00 !ruby puts 'Sam'", from: :uadmin, to: :cbot1cm
      sleep 1
      send_message "see all routines", from: :uadmin, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).not_to match(/To see all routines on all channels you need to run the command on the master channel./)
      expect(buffer(to: channel, from: :ubot).join).not_to match(/I'll display only the routines on this channel./)
      expect(buffer(to: channel, from: :ubot).join).to match(/Routines on channel \*bot1cm\*/)
      expect(buffer(to: channel, from: :ubot).join).to match(/`*example*`/)
      expect(buffer(to: channel, from: :ubot).join).to match(/Status: on/)
    end
  end

  describe "on direct message" do
    channel = DIRECT.user1.ubot
    user = :user1

    it "can be called" do
      send_message "see routines", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can use this command/)
    end
  end
  describe "on extended channel" do
    it "doesn't respond" do
      send_message "!see routines", from: :uadmin, to: :cext1
      expect(buffer(to: :cext1, from: :ubot, tries: 4).join).to eq ""
    end
  end
  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = "see routines"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot, tries: 4).join).to eq ""
    end
  end
end
