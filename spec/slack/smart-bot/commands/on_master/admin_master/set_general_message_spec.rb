
RSpec.describe SlackSmartBot, "set_general_message" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :uadmin

    after(:each) do
      sleep 1
      send_message "bye bot", from: user, to: channel
    end

    it "is not possible to be used" do
      send_message "set general message Example message", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Only master admins on master channel can use this command/)
    end
  end

  describe "on master channel" do
    channel = :cmaster
    user = :uadmin

    after(:each) do
      send_message "set general message off", from: user, to: channel
      send_message "bye bot", from: user, to: channel
    end

    it "doesn't allow to be used if not master admin" do
      send_message "set general message Example message", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to eq "Only master admins on master channel can use this command."
    end

    it 'set general message on and displays supplied message' do
      send_message "set general message Example message", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/General message has been set/)
      send_message "!echo A", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Example message/)
    end

    it 'set general message on and displays message on another channel' do
      send_message "set general message Example message", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/General message has been set/)
      sleep 7
      send_message "!echo A", from: user, to: :cbot1cm
      sleep 1
      expect(buffer(to: :cbot1cm, from: :ubot).join).to match(/Example message/)
    end
    it 'is possible to use interpolation' do
      send_message 'set general message Example #{Time.new(2021,6,18,13,30,0)}', from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/General message has been set/)
      sleep 7
      send_message "!echo A", from: user, to: :cbot1cm
      sleep 1
      expect(buffer(to: :cbot1cm, from: :ubot).join).to match(/Example 2021-06-18 13:30:00/)
    end

    it 'set general message off' do
      send_message "set general message Example message", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/General message has been set/)
      send_message "!echo AAAAA", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Example message/)
      send_message "set general message off", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/General message won't be displayed anymore/)
      sleep 6
      send_message "!echo EEEEEE", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to eq "EEEEEE"
      send_message "!echo UUUUUU", from: user, to: :cbot1cm
      expect(buffer(to: :cbot1cm, from: :ubot)[-1]).to eq "UUUUUU"
    end

  end

  describe "on direct message" do
    channel = DIRECT.user1.ubot
    user = :user1

    it "cannot be called" do
      send_message "set general message Example message", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot)[-1]).to eq "Only master admins on master channel can use this command."
    end
  end
end
