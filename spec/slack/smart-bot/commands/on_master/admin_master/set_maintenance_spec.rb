
RSpec.describe SlackSmartBot, "set_maintenance" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :uadmin

    after(:each) do
      sleep 1
      send_message "bye bot", from: user, to: channel
    end

    it "is not possible to be used" do
      send_message "!set maintenance on", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Only master admins on master channel can use this command/)
    end
  end

  describe "on master channel" do
    channel = :cmaster
    user = :uadmin

    after(:each) do
      send_message "turn maintenance off", from: user, to: channel
      send_message "bye bot", from: user, to: channel
    end

    it "doesn't allow to be used if not master admin" do
      send_message "!set maintenance on", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to eq "Only master admins on master channel can use this command."
    end

    it 'turns maintenance on and displays generic message' do
      send_message "!set maintenance on", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to eq "From now on I'll be on maintenance status so I won't be responding accordingly."
      send_message "!echo A", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to eq "Sorry I'm on maintenance so I cannot attend your request."
    end

    it 'turns maintenance on and displays supplied message' do
      send_message "!set maintenance on specific_message", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to eq "From now on I'll be on maintenance status so I won't be responding accordingly."
      send_message "!echo A", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to eq "specific_message"      
    end

    it 'turns maintenance on and displays generic message on another channel' do
      send_message "!set maintenance on", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot)[-1]).to eq "From now on I'll be on maintenance status so I won't be responding accordingly."
      sleep 7
      send_message "!echo A", from: user, to: :cbot1cm
      sleep 0.5
      expect(buffer(to: :cbot1cm, from: :ubot)[-1]).to eq "Sorry I'm on maintenance so I cannot attend your request."
    end

    it 'turns maintenance off' do
      send_message "set maintenance on", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to eq "From now on I'll be on maintenance status so I won't be responding accordingly."
      send_message "!echo AAAAA", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to eq "Sorry I'm on maintenance so I cannot attend your request."
      send_message "set maintenance off", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot)[-1]).to eq "From now on I won't be on maintenance. Everything is back to normal!"
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
      send_message "set maintenance on", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot)[-1]).to eq "Only master admins on master channel can use this command."
    end
  end
end
