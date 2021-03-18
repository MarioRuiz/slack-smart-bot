RSpec.describe SlackSmartBot, "delete_repl" do
    describe "on channel bot" do
      channel = :cbot1cm
      user = :user1
  
      after(:all) do
        send_message "bye bot", from: user, to: channel
      end

      it 'deletes a repl created by the owner' do
        send_message "!repl deleterepl ", from: user, to: channel
        send_message "bye", from: user, to: channel
        send_message "!delete repl deleterepl ", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/REPL deleterepl deleted/i)
        send_message "!see repls ", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/\(public\) \*deleterepl\*/i)
      end

      it 'cannot delete a repl created by another' do
        send_message "!repl deleterepl1 ", from: :user2, to: channel
        send_message "bye", from: :user2, to: channel

        send_message "!delete repl deleterepl1 ", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Only admins or the creator of this REPL can delete it/i)
        send_message "!see repls ", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\(public\) \*deleterepl1\*/i)
      end

      it 'deletes a repl created by another if admin' do
        send_message "!repl deleterepl2 ", from: user, to: channel
        send_message "bye", from: user, to: channel

        send_message "!delete repl deleterepl2 ", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/REPL deleterepl2 deleted/i)
        sleep 0.5
        send_message "!see repls ", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/\(public\) \*deleterepl2\*/i)
      end

    end
end
  