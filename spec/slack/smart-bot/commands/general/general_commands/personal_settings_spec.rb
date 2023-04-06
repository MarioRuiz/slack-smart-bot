RSpec.describe SlackSmartBot, "personal settings" do
  describe "set personal settings" do
    describe "on external channel" do
      channel = :cexternal
      user = :uadmin
      it "displays error when not on a DM" do
        send_message "set personal settings uno.dos.tres 33", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/This command can only be called on a DM with the SmartBot/i)
      end
    end

    describe "on DM" do
      channel = DIRECT.uadmin.ubot
      user = :uadmin

      it "displays succesful message when using set personal settings" do
        send_message "set personal settings uno.dos.tres 33", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Personal settings set for \*uno.dos.tres\*/i)
      end

      it "displays succesful message when using set personal config" do
        send_message "set personal config uno.dos.tres 33", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Personal settings set for \*uno.dos.tres\*/i)
      end
    end
  end
  describe "get personal settings" do
    user = :uadmin
    before(:all) do
      channel = DIRECT.uadmin.ubot
      send_message "set personal settings uno.dos.tres 33", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Personal settings set for \*uno.dos.tres\*/i)
    end

    describe "on external channel" do
      channel = :cexternal
      it "displays error when not on a DM" do
        send_message "get personal settings uno.dos.tres", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/This command can only be called on a DM with the SmartBot/i)
      end
    end

    describe "on DM" do
      channel = DIRECT.uadmin.ubot
      it "displays succesful message when using get personal settings" do
        send_message "get personal settings uno.dos.tres", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Personal settings for \*uno.dos.tres\* is: \*33\*/i)
      end

      it "displays succesful message when using get personal config" do
        send_message "get personal config uno.dos.tres", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Personal settings for \*uno.dos.tres\* is: \*33\*/i)
      end

      it "displays not found" do
        send_message "get personal settings uno.dos.tres.1", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Personal settings for \*uno.dos.tres.1\* not found/i)
      end

      it 'is updated in other channels' do
        send_message "use #bot1cm", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/I'm using now the rules/i)
        send_message "get personal settings uno.dos.tres", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Personal settings for \*uno.dos.tres\* is: \*33\*/i)
        send_message "use #bot2cu", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/I'm using now the rules/i)
        send_message "get personal settings uno.dos.tres", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Personal settings for \*uno.dos.tres\* is: \*33\*/i)
      end
    end
  end

  describe "delete personal settings" do
    user = :uadmin
    before(:each) do
        channel = DIRECT.uadmin.ubot
        send_message "set personal settings uno.dos.tres 33", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Personal settings set for \*uno.dos.tres\*/i)
    end

    describe "on external channel" do
        channel = :cexternal
        it "displays error when not on a DM" do
            send_message "delete personal settings uno.dos.tres", from: user, to: channel
            expect(buffer(to: channel, from: :ubot).join).to match(/This command can only be called on a DM with the SmartBot/i)
        end
    end

    describe "on DM" do
        channel = DIRECT.uadmin.ubot
        it "displays succesful message when using delete personal settings" do
            send_message "delete personal settings uno.dos.tres", from: user, to: channel
            expect(buffer(to: channel, from: :ubot).join).to match(/Personal settings deleted for \*uno.dos.tres\*/i)
            send_message "get personal settings uno.dos.tres", from: user, to: channel
            expect(buffer(to: channel, from: :ubot).join).to match(/Personal settings for \*uno.dos.tres\* not found/i)
        end

        it "displays succesful message when using delete personal config" do
            send_message "delete personal config uno.dos.tres", from: user, to: channel
            expect(buffer(to: channel, from: :ubot).join).to match(/Personal settings deleted for \*uno.dos.tres\*/i)
            send_message "get personal settings uno.dos.tres", from: user, to: channel
            expect(buffer(to: channel, from: :ubot).join).to match(/Personal settings for \*uno.dos.tres\* not found/i)
        end

        it "displays not found" do
            send_message "delete personal settings uno.dos.tres.1", from: user, to: channel
            expect(buffer(to: channel, from: :ubot).join).to match(/Personal settings for \*uno.dos.tres.1\* not found/i)
        end
        it 'is updated in other channels too' do
            send_message "use #bot1cm", from: user, to: channel
            expect(bufferc(to: channel, from: :ubot).join).to match(/I'm using now the rules/i)
            send_message "delete personal settings uno.dos.tres", from: user, to: channel
            expect(bufferc(to: channel, from: :ubot).join).to match(/Personal settings deleted for \*uno.dos.tres\*/i)
            send_message "use #bot2cu", from: user, to: channel
            expect(bufferc(to: channel, from: :ubot).join).to match(/I'm using now the rules/i)
            send_message "delete personal settings uno.dos.tres", from: user, to: channel
            expect(bufferc(to: channel, from: :ubot).join).to match(/Personal settings for \*uno.dos.tres\* not found/i)
            send_message "get personal settings uno.dos.tres", from: user, to: channel
            expect(bufferc(to: channel, from: :ubot).join).to match(/Personal settings for \*uno.dos.tres\* not found/i)
        end

    end
        

  end

end
