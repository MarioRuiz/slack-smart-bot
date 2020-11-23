RSpec.describe SlackSmartBot, "see_repls" do
    describe "on channel bot" do
      channel = :cbot1cm
      user = :user1
  
      before(:all) do
        send_message "!repl seerepl1 ", from: user, to: channel
        send_message "bye", from: user, to: channel
        send_message "!clean repl seerepl2 ", from: user, to: channel
        send_message "bye", from: user, to: channel
        send_message "!private repl seerepl3 ", from: user, to: channel
        send_message "bye", from: user, to: channel
        send_message "!private repl seerepl4 ", from: :user2, to: channel
        send_message "bye", from: :user2, to: channel
        send_message "!repl seerepl5 ", from: :user2, to: channel
        send_message "bye", from: :user2, to: channel
      end
      after(:all) do
        send_message "bye bot", from: user, to: channel
      end

      it 'list all public repls' do
        send_message "!see repls", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\(public\) \*seerepl1\*/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\(public_clean\) \*seerepl2\*/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\(public\) \*seerepl5\*/i)
      end

      it 'list my private repls' do
        send_message "!see repls", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\(private\) \*seerepl3\*/i)
      end

      it 'doesn\'t list others private repls' do
        send_message "!see repls", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/\(private\) \*seerepl4\*/i)
      end

      it 'displays the creator' do
        send_message "!see repls", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/creator: smartbotuser1/i)
      end


      it 'counts runs' do
        send_message "!run repl seerepl1", from: user, to: channel
        sleep 0.5
        send_message "!see repls", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/runs: 1/i)
      end

      it 'counts gets' do
        send_message "!get repl seerepl1", from: user, to: channel
        sleep 0.5
        send_message "!see repls", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/gets: 1/i)
      end

    end
end
  