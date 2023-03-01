
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
      send_message 'delete routine example2', from: user, to: channel
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

    it 'There are no routines added that match the header name and the regexp xxxx' do
      sleep 1
      send_message "see routines name /xxxx/", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/There are no routines added that match the header \*name\* and the regexp \*xxxx\*/)
    end

    it 'There are routines added that match the header name and the regexp example' do
      sleep 2
      send_message "see routines name /example/", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/Routines on channel \*bot1cm\* that match the header \*name\* and the regexp \*example\*/)
    end

    it 'There are no routines added that match the header status and the regexp xxxx' do
      sleep 1
      send_message "see routines status /xxxx/", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/There are no routines added that match the header \*status\* and the regexp \*xxxx\*/)
    end

    it 'There are routines added that match the header status and the regexp on' do
      sleep 2
      send_message "see routines status /on/", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/Routines on channel \*bot1cm\* that match the header \*status\* and the regexp \*on\*/)
    end

    it 'There are no routines added that match the header creator and the regexp xxxx' do
      sleep 1
      send_message "see routines creator /xxxx/", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/There are no routines added that match the header \*creator\* and the regexp \*xxxx\*/)
    end

    it 'There are routines added that match the header creator and the regexp mario' do
      sleep 2
      send_message "see routines creator /mario/", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/Routines on channel \*bot1cm\* that match the header \*creator\* and the regexp \*mario\*/)
    end

    it 'There are no routines added that match the header next_run and the regexp xxxx' do
      sleep 1
      send_message "see routines next_run /xxxx/", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/There are no routines added that match the header \*next_run\* and the regexp \*xxxx\*/)
    end

    it 'There are routines added that match the header next_run and the regexp 00:00' do
      sleep 2
      send_message "see routines next_run /00:00/", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/Routines on channel \*bot1cm\* that match the header \*next_run\* and the regexp \*00:00\*/)
    end

    it 'There are no routines added that match the header last_run and the regexp xxxx' do
      sleep 1
      send_message "see routines last_run /xxxx/", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/There are no routines added that match the header \*last_run\* and the regexp \*xxxx\*/)
    end

    it 'There are routines added that match the header last_run and the regexp for Date.today' do
      send_message "add routine example2 every 60m !ruby puts 'exa2'", from: user, to: channel
      sleep 2
      send_message "see routines last_run /#{Date.today}/", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/Routines on channel \*bot1cm\* that match the header \*last_run\* and the regexp \*#{Date.today}\*/)
    end

    it 'There are no routines added that match the header command and the regexp xxxx' do
      sleep 1
      send_message "see routines command /xxxx/", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/There are no routines added that match the header \*command\* and the regexp \*xxxx\*/)
    end

    it 'There are routines added that match the header command and the regexp ruby' do
      sleep 2
      send_message "see routines command /ruby/", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/Routines on channel \*bot1cm\* that match the header \*command\* and the regexp \*ruby\*/)
    end
    
    it 'displays no routines when no routines added' do
      sleep 1
      send_message "delete routine example", from: user, to: channel
      send_message "delete routine example2", from: user, to: channel
      sleep 2
      send_message "see routines", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/There are no routines added/)
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

    it "displays routines for 'see all routines name /example/'" do
      send_message "see all routines name /example/", from: :uadmin, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).not_to match(/To see all routines on all channels you need to run the command on the master channel./)
      expect(buffer(to: channel, from: :ubot).join).not_to match(/I'll display only the routines on this channel./)
      expect(buffer(to: channel, from: :ubot).join).to match(/Routines on channel \*bot1cm\* that match the header \*name\* and the regexp \*example\*/)
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
      expect(buffer(to: :cext1, from: :ubot).join).to  match(/Similar rules/)
    end
  end
  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = "see routines"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/I don't understand/)
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/Take in consideration when on external calls/)
    end
  end
end
