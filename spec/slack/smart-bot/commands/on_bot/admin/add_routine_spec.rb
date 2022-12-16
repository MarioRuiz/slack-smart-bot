
RSpec.describe SlackSmartBot, "add_routine" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :uadmin
    @regexp_dont_understand = ["what?", "huh?", "sorry?", "what do you mean?", "I don't understand"].join("|")
    
    before(:all) do
      sleep 1
      send_message "delete routine example", from: user, to: channel
    end

    after(:each) do
      sleep 1
      send_message "delete routine example", from: user, to: channel
    end

    it "creates the routine every 2 sc" do
      sleep 1
      clean_buffer()
      send_message "add routine example every 2s !ruby puts 'Sam'", from: user, to: channel
      sleep 6
      res = buffer(to: channel, from: :ubot)
      expect(res[0]).to match(/Added routine \*`example`\* to the channel/)
      expect(res[1]).to match(/^routine \*`example`\*: !ruby puts 'Sam'$/)
      expect(res[2]).to match(/^Sam$/)
      expect(res[3]).to match(/^routine \*`example`\*: !ruby puts 'Sam'$/)
      expect(res[4]).to match(/^Sam$/)
    end

    it "creates the routine every 2 sc using a rule" do
      sleep 1
      clean_buffer()
      send_message "add routine example every 2s !echo Sam", from: user, to: channel
      sleep 6
      res = buffer(to: channel, from: :ubot)
      expect(res[0]).to match(/Added routine \*`example`\* to the channel/)
      expect(res[1]).to match(/^routine \*`example`\*: !echo Sam$/)
      expect(res[2]).to match(/^Sam$/)
      expect(res[3]).to match(/^routine \*`example`\*: !echo Sam$/)
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

    it "creates the routine every 2 sc and publish on specified channel" do
      send_message "add routine example every 2s <##{CBOT2CU}|bot2cu> !ruby puts 'Sam'", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Added routine \*`example`\* to the channel/)
      sleep 4
      res = buffer(to: :cbot2cu, from: :ubot)
      expect(res[0]).to match(/^routine from <##{CBOT1CM}> \*`example`\*: !ruby puts 'Sam'$/)
      expect(res[1]).to match(/^Sam$/)
    end

    it 'creates a silent routine and is displayed only when returns message' do
      routine = "!test silent #{Time.now+7}"

      send_message "add silent routine example every 2s #{routine}", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Added routine \*`example`\* to the channel/)
      sleep 3
      expect(buffer(to:channel, from: :ubot, tries: 1).join).to eq ''
      sleep 7
      res = buffer(to: channel, from: :ubot).join
      #expect(res).to match(/routine \*`example`\*: !ruby puts 'Now yes'/)
      expect(res).to match(/[^']Now yes/)
    end

    it "creates a silent bgroutine" do
      send_message "add silent bgroutine example every 2s !ruby puts 'Sam'", from: user, to: channel
      sleep 6
      res = bufferc(to: channel, from: :ubot).join
      expect(res).to match(/Added routine \*`example`\* to the channel/)
      sleep 2
      res = buffer(to: channel, from: :ubot).join
      expect(res).not_to match(/Sam/)
      expect(res).not_to match(/routine \*`example`\*: !ruby puts 'Sam'/)
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

    it "doesn't allow to create routine if already exist with same name" do
      send_message "create routine example every 200s !ruby puts 'Sam'", from: user, to: channel
      sleep 3
      send_message "create routine example every 200s !ruby puts 'Sam'", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/I'm sorry but there is already a routine with that name/)
    end

    it "doesn't allow to create routine when wrong time" do
      send_message "create routine example at 25:33 !ruby puts 'Sam'", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Wrong time specified/)
    end

    it 'creates routine supplying days' do
      started = Time.now+2
      send_message "create routine example every 2 days !ruby puts 'Sam'", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Added routine \*`example`\* to the channel/)
      send_message 'see routines', from: user, to: channel
      sleep 3
      expect(buffer(to: channel, from: :ubot).join).to match(/Next Run: #{(started+(24*2*60*60)).strftime("%Y-%m-%d")}/)
    end

    it 'creates routine supplying hours' do
      started = Time.now+2
      send_message "create routine example every 2 hours !ruby puts 'Sam'", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Added routine \*`example`\* to the channel/)
      send_message 'see routines', from: user, to: channel
      sleep 3
      expect(buffer(to: channel, from: :ubot).join).to match(/Next Run: #{(started+(2*60*60)).strftime("%Y-%m-%d %H:%M")}/)
    end

    it 'creates routine supplying minutes' do
      started = Time.now+2
      send_message "create routine example every 2 minutes !ruby puts 'Sam'", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Added routine \*`example`\* to the channel/)
      send_message 'see routines', from: user, to: channel
      sleep 3
      expect(buffer(to: channel, from: :ubot).join).to match(/Next Run: #{(started+(2*60)).strftime("%Y-%m-%d %H:%M")}/)
    end

    it "creates the routine on weekends" do
      send_message "add routine example on weekends at 10:00 !ruby puts 'Sam'", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Added routine \*`example`\* to the channel/)
    end

    it "creates the routine on weekdays" do
      send_message "add routine example on weekdays at 10:00 !ruby puts 'Sam'", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to match(/Added routine \*`example`\* to the channel/)
    end

    unless SIMULATE
      it "doesn't allow to create routine attaching file if not master admin" do
        send_message "create routine example every 2s", from: :user1, to: :cbot2cu, file_ruby: "puts 'Sam'"
        sleep 2
        expect(buffer(to: :cbot2cu, from: :ubot).join).to match(/Only master admin users can add files to routines/)
      end
    end

    unless SIMULATE
      it "creates routine attaching file if master admin" do
        send_message "create routine example every 2s", from: user, to: channel, file_ruby: "puts 'Sam'"
        sleep 6
        res = buffer(to: channel, from: :ubot).join
        expect(res).to match(/Added routine \*`example`\* to the channel/)
        expect(res).to match(/routine \*`example`\*: \.\/routines\/#{CBOT1CM}\/example\.rb/)
        expect(res).to match(/Sam/)
      end
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
      expect(buffer(to: :cext1, from: :ubot).join).to match(/#{@regexp_dont_understand}/)
    end
  end

  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = 'add routine example every 2s !ruby puts "Sam"'
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/#{@regexp_dont_understand}/)
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/Take in consideration when on external calls/)
  end
  end
end
