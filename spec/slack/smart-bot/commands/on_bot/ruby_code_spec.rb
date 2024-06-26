
RSpec.describe SlackSmartBot, "ruby_code" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :user1

    after(:all) do
      send_message "bye bot", from: user, to: channel
    end

    it "works: ruby puts 'Example' on demand" do
      send_message "!ruby puts 'Example'", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^Example$/)
    end

    it "works: code puts 'Example' on demand" do
      send_message "!code puts 'Example'", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^Example$/)
    end

    it "works: ruby puts 'Example' when listening" do
      send_message "Hi bot", from: user, to: channel
      send_message "ruby puts 'Example'", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Example/)
    end

    it "displays message when nothing returned" do
      send_message "!ruby 3+2", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^Nothing returned. Remember you need to use p or puts to print$/)
    end
    it "displays security error" do
      send_message "!ruby puts ENV['AAA']", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^Sorry I cannot run this due security reasons$/)
    end
    it "works: when supplying a code block" do
      send_message "!ruby
      ```
      a = 123456 + 1
      puts a
      ```", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^123457$/)
    end
  end

  describe "on master channel" do
    channel = :cmaster
    user = :user2

    after(:all) do
      send_message "bye bot", from: user, to: channel
    end

    it "works: ruby puts 'Example' on demand" do
      send_message "!ruby puts 'Example'", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^Example$/)
    end

    it "works: code puts 'Example' on demand" do
      send_message "!code puts 'Example'", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^Example$/)
    end

    it "works: ruby puts 'Example' when listening" do
      send_message "Hi bot", from: user, to: channel
      send_message "ruby puts 'Example'", from: user, to: channel
      sleep 0.5 if SIMULATE
      expect(buffer(to: channel, from: :ubot).join).to match(/Example/)
    end
  end

  describe "on direct message" do
    channel = DIRECT.user1.ubot
    user = :user1

    it "works: ruby puts 'Example'" do
      send_message "ruby puts 'Example'", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^Example$/)
    end

    it "works: code puts 'Example'" do
      send_message "code puts 'Example'", from: user, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^Example$/)
    end
  end

  describe "on extended channel" do
    channel = :cext1

    it "works: ruby puts 'Example' on demand" do
      send_message "!ruby puts 'Example'", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^Example$/)
    end

    it "works even for user not part of original channel" do
      send_message "!ruby puts 'Example'", from: :user2, to: channel
      expect(buffer(to: channel, from: :ubot)[-1]).to match(/^Example$/)
    end

    it "doesn't work if not in demand" do
      send_message "ruby puts 'Example", from: :user2, to: :cext1
      expect(buffer(to: :cext1, from: :ubot).join).to eq ""
    end
  end

  describe "on external channel not extended" do
    it "responds to external demand" do
      command = 'ruby puts "a"'
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      expect(buffer(to: :cexternal, from: :ubot, tries: 10).join).not_to eq ""
    end
  end
end
