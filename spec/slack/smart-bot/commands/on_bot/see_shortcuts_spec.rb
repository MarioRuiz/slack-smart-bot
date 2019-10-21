
RSpec.describe SlackSmartBot, "see_shortcuts" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :user1

    before(:all) do
      send_message "!delete shortcut example", from: :uadmin, to: channel
      send_message "yes", from: :uadmin, to: channel
      send_message "!delete shortcut example", from: user, to: channel
      send_message "yes", from: user, to: channel
      send_message "!delete shortcut example2", from: user, to: channel
      send_message "yes", from: user, to: channel
      send_message "!delete shortcut example2", from: :uadmin, to: channel
      send_message "yes", from: :uadmin, to: channel
      send_message "!delete shortcut example3", from: :uadmin, to: channel
      send_message "yes", from: :uadmin, to: channel
      clean_buffer()
      sleep 1
    end

    after(:each) do
      send_message "bye bot", from: user, to: channel
    end

    it "displays shortcuts" do
      send_message "!add shortcut example: echo Text", from: user, to: channel
      send_message "!add shortcut for all example2: echo Text", from: user, to: channel
      send_message "!add shortcut example3: echo Text3", from: :uadmin, to: channel
      send_message "!see shortcuts", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Available shortcuts for smartbotuser1/)
      expect(buffer(to: channel, from: :ubot).join).to match(/example: echo Text/)
      expect(buffer(to: channel, from: :ubot).join).to match(/example2: echo Text/)
      expect(buffer(to: channel, from: :ubot).join).to match(/Available shortcuts for all/)
      expect(buffer(to: channel, from: :ubot).join).not_to match(/example3: echo Text3/)
    end

    it "responds when listening" do
      send_message "Hi bot", from: user, to: channel
      send_message "see shortcuts", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/(No shortcuts found|Available shortcuts)/)
    end

    it "responds to see sc" do
      send_message "Hi bot", from: user, to: channel
      send_message "see sc", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/(No shortcuts found|Available shortcuts)/)
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

    it "displays shortcuts" do
      send_message "!add sc example: echo Text", from: user, to: channel
      send_message "!see shortcuts", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Available shortcuts for smartbotuser2/)
      expect(buffer(to: channel, from: :ubot).join).to match(/example: echo Text/)
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

    it "displays shortcuts" do
      send_message "!add sc example: echo Text", from: user, to: channel
      send_message "!see shortcuts", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Available shortcuts for smartbotuser1/)
      expect(buffer(to: channel, from: :ubot).join).to match(/example: echo Text/)
    end
  end

  describe "on extended channel" do
    it "doesn't respond" do
      send_message "!see shortcuts", from: :uadmin, to: :cext1
      expect(buffer(to: :cext1, from: :ubot, tries: 4).join).to eq ""
    end
  end
  describe "on external channel not extended" do
    it "responds to external demand" do
      command = "see shortcuts"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot, tries: 4).join).not_to eq ""
    end
  end
end
