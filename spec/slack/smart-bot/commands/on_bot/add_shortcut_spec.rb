
RSpec.describe SlackSmartBot, "add_shortcut" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :user1

    before(:each) do
      send_message "!delete shortcut example", from: :uadmin, to: channel
      send_message "yes", from: :uadmin, to: channel
      send_message "!delete shortcut example", from: user, to: channel
      send_message "yes", from: user, to: channel
      clean_buffer()
    end

    after(:each) do
      send_message "bye bot", from: user, to: channel
    end

    it "works: add shortcut on demand" do
      send_message "!add shortcut example: echo Text", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/shortcut added/)
    end

    it "works: add shortcut when listening" do
      send_message "Hi bot", from: user, to: channel
      send_message "add shortcut example: echo Text", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/shortcut added/)
    end

    it "works: add sc" do
      send_message "!add sc example: echo Text", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/^shortcut added$/)
    end

    it "works: add shortcut for all" do
      send_message "!add shortcut for all example: echo Text", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/^shortcut added$/)
    end

    it "works: shortcut" do
      send_message "!shortcut example: echo Text", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/^shortcut added$/)
    end

    it "works: shortcut for all" do
      send_message "!shortcut for all example: echo Text", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/^shortcut added$/)
    end

    it "calls shortcut using: shortcut NAME" do
      send_message "!shortcut example: echo Text", from: user, to: channel
      send_message "!shortcut example", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^Text$/)
    end
    it "calls shortcut using: sc NAME" do
      send_message "!shortcut example: echo Text", from: user, to: channel
      send_message "!sc example", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^Text$/)
    end
    it "calls shortcut using: NAME" do
      send_message "!shortcut example: echo Text", from: user, to: channel
      send_message "!example", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^Text$/)
    end
    it "cannot use a shortcut added by other user" do
      send_message "!shortcut example: echo Text", from: user, to: channel
      send_message "!example", from: :uadmin, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/I don't understand/)
      expect(buffer(to: channel, from: :ubot)[-1]).not_to match(/^Text$/)
    end
    it "can use a shortcut added by other user when using for all" do
      send_message "!shortcut for all example: echo Text", from: user, to: channel
      send_message "!example", from: :uadmin, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^Text$/)
    end
    it "can modify a shortcut added by yourself" do
      send_message "!shortcut example: echo Text", from: user, to: channel
      send_message "!shortcut example: echo Text2", from: user, to: channel
      message = "The shortcut already exists, are you sure you want to overwrite it?"
      expect(bufferc(to: channel, from: :ubot)[-1]).to match(/#{message}/)
      send_message "yes", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot)[-1]).to match(/shortcut added/)
      send_message "!example", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^Text2$/)
    end

    it "cannot modify a shortcut for all added by other" do
      send_message "!shortcut for all example: echo Text", from: :uadmin, to: channel
      send_message "!shortcut for all example: echo Text2", from: user, to: channel
      sleep 1
      message = "Only the creator of the shortcut can modify it"
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/#{message}/)
    end
    it "cannot add a shortcut for all when other user use the same name" do
      send_message "!shortcut example: echo Text", from: :uadmin, to: channel
      send_message "!shortcut for all example: echo Text2", from: user, to: channel
      sleep 1
      message = "You cannot create a shortcut for all with the same name than other user is using"
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/#{message}/)
    end
    it "calls shortcut on inline command" do
      send_message "!shortcut example: This is a text to display", from: user, to: channel
      send_message "!echo $example", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^This is a text to display$/)
    end
    it "calls two shortcuts on inline command" do
      send_message "!shortcut example: This is a text to display", from: user, to: channel
      send_message "!shortcut love: Love is in the air", from: user, to: channel
      clean_buffer()
      send_message "!echo $example $love", from: user, to: channel
      sleep 2
      buff = buffer(to: channel, from: :ubot).join
      send_message "!delete shortcut love", from: user, to: channel
      send_message "yes", from: user, to: channel
      expect(buff).to match(/This is a text to display\sLove is in the air/)
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

    it "calls shortcut using: shortcut NAME" do
      send_message "!shortcut example: echo Text", from: user, to: channel
      send_message "!shortcut example", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^Text$/)
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

    it "calls shortcut using: shortcut NAME" do
      send_message "shortcut example: ruby puts 'Text'", from: user, to: channel
      send_message "shortcut example", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^Text$/)
    end
  end

  describe "on extended channel" do
    before(:all) do
      send_message "!delete shortcut example", from: :uadmin, to: :cbot1cm
      send_message "yes", from: :uadmin, to: :cbot1cm
      sleep 1
      clean_buffer()
    end

    after(:all) do
      send_message "!delete shortcut example", from: :uadmin, to: :cbot1cm
      send_message "yes", from: :uadmin, to: :cbot1cm
      sleep 1
      clean_buffer()
    end

    it "responds to existing shortcut" do
      send_message "!add shortcut example: echo Text", from: :uadmin, to: :cbot1cm
      send_message "!shortcut example", from: :uadmin, to: :cext1
      sleep 2
      expect(buffer(to: :cext1, from: :ubot).join).to eq "Text"
    end
    it "is not possible to add shortcut" do
      send_message "!add shortcut example: echo Text", from: :uadmin, to: :cext1
      sleep 2
      expect(buffer(to: :cext1, from: :ubot, tries: 4).join).to eq ""
    end
  end

  describe "on external channel not extended" do
    after(:all) do
      send_message "!delete shortcut example", from: :uadmin, to: :cbot1cm
      send_message "yes", from: :uadmin, to: :cbot1cm
      sleep 1
      clean_buffer()
    end

    it "is possible to add a shortcut" do
      command = "!add shortcut example: echo Text"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      sleep 2
      expect(buffer(to: :cexternal, from: :ubot, tries: 4).join).not_to eq ""
    end
    it "responds to existing shortcut when external demand" do
      command = "shortcut example"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      sleep 2
      expect(buffer(to: :cexternal, from: :ubot, tries: 4).join).not_to eq ""
    end
  end
end
