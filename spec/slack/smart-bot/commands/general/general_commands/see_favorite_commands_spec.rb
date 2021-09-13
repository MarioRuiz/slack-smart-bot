
RSpec.describe SlackSmartBot, "see_favorite_commands" do
  describe "see favorite commands" do
    describe "on bot" do
      before(:all) do
        FileUtils.rm_rf(Dir["./spec/bot/stats/*"])
        send_message "see statuses", from: :user1, to: :cbot1cm
        send_message "!echo example", from: :user2, to: :cbot1cm
      end

      it "see favorite commands" do
        send_message "see favorite commands", from: :user1, to: :cbot1cm
        resp = buffer(to: :cbot1cm, from: :ubot).join
        expect(resp).to match(/echo/i)
        expect(resp).to match(/see statuses/i)
        expect(resp).to match(/favorite commands/i)
      end
      it "see favourite commands" do
        send_message "see favourite commands", from: :user1, to: :cbot1cm
        resp = buffer(to: :cbot1cm, from: :ubot).join
        expect(resp).to match(/echo/i)
        expect(resp).to match(/see statuses/i)
        expect(resp).to match(/favorite commands/i)
      end
      it "see most used commands" do
        send_message "see most used commands", from: :user1, to: :cbot1cm
        resp = buffer(to: :cbot1cm, from: :ubot).join
        expect(resp).to match(/echo/i)
        expect(resp).to match(/see statuses/i)
        expect(resp).to match(/favorite commands/i)
      end
      it "see fav commands" do
        send_message "see fav commands", from: :user1, to: :cbot1cm
        resp = buffer(to: :cbot1cm, from: :ubot).join
        expect(resp).to match(/echo/i)
        expect(resp).to match(/see statuses/i)
        expect(resp).to match(/favorite commands/i)
      end
      it "see my favorite commands" do
        send_message "see my favorite commands", from: :user1, to: :cbot1cm
        resp = buffer(to: :cbot1cm, from: :ubot).join
        expect(resp).not_to match(/echo/i)
        expect(resp).to match(/see statuses/i)
        expect(resp).to match(/favorite commands/i)
        send_message "see my favorite commands", from: :user2, to: :cbot1cm
        resp = buffer(to: :cbot1cm, from: :ubot).join
        expect(resp).to match(/echo/i)
        expect(resp).to match(/see statuses/i)
        expect(resp).to match(/favorite commands/i)
      end
    end

    describe "on master channel" do
      it "see favorite commands" do
        channel = :cmaster
        FileUtils.rm_rf(Dir["./spec/bot/stats/*"])
        send_message "see statuses", from: :user1, to: channel
        send_message "!echo example", from: :user2, to: channel

        send_message "see favorite commands", from: :user1, to: channel
        resp = buffer(to: channel, from: :ubot).join
        expect(resp).to match(/echo/i)
        expect(resp).to match(/see statuses/i)
        expect(resp).to match(/favorite commands/i)
      end
    end

    describe "on direct message" do
      it "see favorite commands" do
        channel = DIRECT.user1.ubot
        FileUtils.rm_rf(Dir["./spec/bot/stats/*"])
        send_message "use #bot1cm", from: :user1, to: channel
        send_message "see statuses", from: :user1, to: channel
        send_message "!echo example", from: :user2, to: :cbot1cm

        send_message "see favorite commands", from: :user1, to: channel
        resp = buffer(to: channel, from: :ubot).join
        expect(resp).to match(/echo/i)
        expect(resp).to match(/see statuses/i)
        expect(resp).to match(/favorite commands/i)
      end
    end

    describe "on channel with extended rules" do
      it "see favorite commands" do
        channel = :cext1
        FileUtils.rm_rf(Dir["./spec/bot/stats/*"])
        send_message "see statuses", from: :user1, to: channel
        send_message "!echo example", from: :user2, to: channel

        send_message "see favorite commands", from: :user1, to: channel
        resp = buffer(to: channel, from: :ubot).join
        expect(resp).to match(/echo/i)
        expect(resp).to match(/see statuses/i)
        expect(resp).to match(/favorite commands/i)
      end
    end

    describe "on private channel with extended rules" do
      it "see favorite commands" do
        channel = :cprivext
        FileUtils.rm_rf(Dir["./spec/bot/stats/*"])
        send_message "see statuses", from: :user1, to: channel
        send_message "!echo example", from: :user2, to: channel

        send_message "see favorite commands", from: :user1, to: channel
        resp = buffer(to: channel, from: :ubot).join
        expect(resp).to match(/echo/i)
        expect(resp).to match(/see statuses/i)
        expect(resp).to match(/favorite commands/i)
      end
    end

    describe "on external channel not extended" do
      it "see favorite commands" do
        channel = :cexternal
        FileUtils.rm_rf(Dir["./spec/bot/stats/*"])
        send_message "see statuses", from: :user1, to: channel

        send_message "see favorite commands", from: :user1, to: channel
        resp = buffer(to: channel, from: :ubot).join
        expect(resp).to match(/see statuses/i)
        expect(resp).to match(/favorite commands/i)
      end
    end


  end
end
