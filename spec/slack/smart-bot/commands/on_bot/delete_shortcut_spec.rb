
RSpec.describe SlackSmartBot, "delete_shortcut" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :user1

    before(:all) do
      send_message "!delete shortcut example", from: :uadmin, to: channel
      send_message "yes", from: :uadmin, to: channel
      send_message "!delete shortcut example", from: user, to: channel
      send_message "yes", from: user, to: channel
      send_message "!delete shortcut example2", from: :uadmin, to: channel
      send_message "yes", from: :uadmin, to: channel
      clean_buffer()
      sleep 1
    end

    before(:each) do
      send_message "!add shortcut example: echo Text", from: user, to: channel
      send_message "yes", from: user, to: channel
      sleep 1
    end

    after(:each) do
      send_message "bye bot", from: user, to: channel
    end

    it "works: delete shortcut on demand" do
      send_message "!delete shortcut example", from: user, to: channel
      sleep 0.5 if SIMULATE
      expect(bufferc(to: channel, from: :ubot)[-1]).to match(/are you sure you want to delete it?/)
      send_message "yes", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[0]).to match(/shortcut deleted/)
    end

    it "works: delete shortcut when listening" do
      send_message "Hi bot", from: user, to: channel
      send_message "delete shortcut example", from: user, to: channel
      sleep 0.5 if SIMULATE

      expect(bufferc(to: channel, from: :ubot)[-1]).to match(/are you sure you want to delete it?/)
      send_message "yes", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[0]).to match(/shortcut deleted/)
    end

    it "works: delete sc" do
      send_message "!delete sc example", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot)[-1]).to match(/are you sure you want to delete it?/)
      send_message "yes", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[0]).to match(/shortcut deleted/)
    end

    it "deletes shortcut for all" do
      send_message "!add shortcut for all example: echo Text", from: user, to: channel
      send_message "yes", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot)[-1]).to match(/^shortcut added$/)
      send_message "!delete sc example", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot)[-1]).to match(/are you sure you want to delete it?/)
      send_message "yes", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot)[0]).to match(/shortcut deleted/)
      send_message "!example", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/I don't understand/)
    end

    it "cannot delete a shortcut for all added by other user" do
      send_message "!add shortcut for all example5: echo Text", from: :uadmin, to: channel
      send_message "yes", from: :uadmin, to: channel
      expect(bufferc(to: channel, from: :ubot)[-1]).to match(/^shortcut added$/)
      send_message "!delete sc example5", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/Only the creator of the shortcut or an admin user can delete it/)
    end

    it "can delete a shortcut for all added by other user if you are user admin" do
      send_message "!add shortcut for all example2: echo Text", from: user, to: channel
      send_message "yes", from: user, to: channel
      send_message "!delete sc example2", from: :uadmin, to: channel
      expect(bufferc(to: channel, from: :ubot)[-1]).to match(/are you sure you want to delete it?/)
      send_message "yes", from: :uadmin, to: channel
      expect(bufferc(to: channel, from: :ubot)[0]).to match(/shortcut deleted/)
    end

    it 'is not possible to delete a global sc' do
      send_message "!delete global shortcut exampleglobdel", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/It is only possible to delete global shortcuts from Master channel/i)  
    end

  end

  describe "on master channel" do
    channel = :cmaster
    user = :user2

    before(:each) do
      send_message "!delete shortcut example", from: user, to: channel
      send_message "yes", from: user, to: channel
      sleep 1
      clean_buffer()
    end

    after(:each) do
      send_message "bye bot", from: user, to: channel
    end

    it "deletes shortcut" do
      send_message "!add sc example: echo Text", from: user, to: channel
      send_message "!delete shortcut example", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot)[-1]).to match(/are you sure you want to delete it?/)
      send_message "yes", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[0]).to match(/shortcut deleted/)
    end

    it "deletes global shortcut" do
      send_message "!add global sc exampleglobaldel: echo Text", from: user, to: channel
      send_message "!delete global shortcut exampleglobaldel", from: user, to: channel
      sleep 1
      expect(buffer(to: channel, from: :ubot).join).to match(/global shortcut deleted!/i)
      send_message "!exampleglobaldel", from: user, to: channel
      sleep 1
      expect(buffer(to: channel, from: :ubot).join).to match(/I don't understand/i)
      send_message "!exampleglobaldel", from: user, to: :cbot1cm
      sleep 1
      expect(buffer(to: :cbot1cm, from: :ubot).join).to match(/I don't understand/i)
    end
    
  end

  describe "on direct message" do
    channel = DIRECT.user1.ubot
    user = :user1

    before(:each) do
      send_message "delete shortcut example", from: user, to: channel
      send_message "yes", from: user, to: channel
      sleep 1
      clean_buffer()
    end
    after(:each) do
      send_message "bye bot", from: user, to: channel
    end

    it "deletes shortcut" do
      send_message "!add sc example: echo Text", from: user, to: channel
      send_message "!delete shortcut example", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot)[-1]).to match(/are you sure you want to delete it?/)
      send_message "yes", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[0]).to match(/shortcut deleted/)
    end
  end

  describe "on extended channel" do
    it "doesn't respond" do
      send_message "!delete shortcut example", from: :uadmin, to: :cext1
      expect(buffer(to: :cext1, from: :ubot, tries: 4).join).to eq ""
    end
  end

  describe "on external channel not extended" do
    after(:each) do
      send_message "bye bot", from: :uadmin, to: :cexternal
    end
    it "responds to external demand" do
      command = "delete shortcut example"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot, tries: 4).join).not_to eq ""
    end
  end
end
