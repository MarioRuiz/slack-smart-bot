
RSpec.describe SlackSmartBot, "add_routine" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :uadmin

    after(:each) do
      sleep 1
      send_message "delete routine example", from: user, to: channel
    end

    it "creates the routine every 2 sc" do
      send_message "add routine example every 2s !ruby puts 'Sam'", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Added routine \*`example`\* to the channel/)
      sleep 4
      res = buffer(to: channel, from: :ubot)
      expect(res[1]).to match(/^routine \*`example`\*: !ruby puts 'Sam'$/)
      expect(res[2]).to match(/^Sam$/)
      expect(res[3]).to match(/^routine \*`example`\*: !ruby puts 'Sam'$/)
      expect(res[4]).to match(/^Sam$/)
    end
    it "creates the routine at certain time" do
      time = Time.now
      send_message "add routine example at #{(time + 10).strftime("%H:%M:%S")} !ruby puts 'Sam'", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Added routine \*`example`\* to the channel/)
      sleep 1
      expect(buffer(to: channel, from: :ubot).join).to eq ""
      sleep (10 - (Time.now - time) + 1)
      res = buffer(to: channel, from: :ubot)
      expect(res[0]).to match(/^routine \*`example`\*: !ruby puts 'Sam'$/)
      expect(res[1]).to match(/^Sam$/)
    end

    it "accepts on demand" do
      send_message "!add routine example every 2s !ruby puts 'Sam'", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Added routine \*`example`\* to the channel/)
    end

    it "accepts 'create routine'" do
      send_message "create routine example every 2s !ruby puts 'Sam'", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Added routine \*`example`\* to the channel/)
    end

    it "doesn't allow to create routine if not admin" do
      send_message "create routine example every 2s !ruby puts 'Sam'", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Only admin users can use this command/)
    end

    it "doesn't allow to create routine attaching file if not master admin" do
      send_message "create routine example every 2s", from: :user1, to: :cbot2cu, file_ruby: "puts 'Sam'"
      sleep 2
      expect(buffer(to: :cbot2cu, from: :ubot).join).to match(/Only master admin users can add files to routines/)
    end

    it "creates routine attaching file if master admin" do
      send_message "create routine example every 2s", from: user, to: channel, file_ruby: "puts 'Sam'"
      sleep 6
      res = buffer(to: channel, from: :ubot).join
      expect(res).to match(/Added routine \*`example`\* to the channel/)
      expect(res).to match(/routine \*`example`\*: Sam/)
    end
  end

  describe "on master channel" do
    channel = :cmaster
    user = :user1

    after(:all) do
      send_message "bye bot", from: user, to: channel
    end

    it "can be called" do
      send_message "add routine example every 2s !ruby puts 'Sam'", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can use this command/)
    end
  end

  describe "on direct message" do
    channel = DIRECT.user1.ubot
    user = :user1

    it "can be called" do
      send_message "add routine example every 2s !ruby puts 'Sam'", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Only admin users can use this command/)
    end
  end

  describe "on extended channel" do
    it "doesn't respond" do
      send_message "!add routine example every 2s !ruby puts 'Sam'", from: :uadmin, to: :cext1
      expect(buffer(to: :cext1, from: :ubot, tries: 4).join).to eq ""
    end
  end

  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = 'add routine example every 2s !ruby puts "Sam"'
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot, tries: 4).join).to eq ""
    end
  end
end