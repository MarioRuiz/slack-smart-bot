
RSpec.describe SlackSmartBot, "publish_announcements" do
  before(:all) do
    send_message "add announcement Example of message", from: :user1, to: :cexternal
    expect(buffer(to: :cexternal, from: :ubot).join).to match(/The announcement has been added/i)
  end

  describe "on channel bot" do
    channel = :cbot1cm
    user = :uadmin
    it "is not possible to be used" do
      send_message "publish announcements", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Only master admins on master channel can use this command/)
    end
  end

  describe "on master channel" do
    channel = :cmaster
    user = :uadmin

    it "doesn't allow to be used if not master admin" do
      send_message "publish announcements", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to eq "Only master admins on master channel can use this command."
    end

    it 'publishes the announcements' do
      send_message "publish announcements", from: user, to: channel
      expect(buffer(to: :cexternal, from: :ubot).join).to match(/Example of message/i)
    end
  end

  describe "on direct message" do
    channel = DIRECT.user1.ubot
    user = :user1

    it "cannot be called" do
      send_message "publish announcements", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot)[-1]).to eq "Only master admins on master channel can use this command."
    end
  end
end
