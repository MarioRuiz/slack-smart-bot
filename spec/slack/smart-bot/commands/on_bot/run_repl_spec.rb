RSpec.describe SlackSmartBot, "run_repl" do
    describe "on channel bot" do
      channel = :cbot1cm
      user = :user1
  
      after(:all) do
        send_message "bye bot", from: user, to: channel
      end

      it 'runs the specified repl' do
        send_message "!repl runreplexe ", from: user, to: channel
        send_message "puts 'done'", from: user, to: channel
        send_message "bye", from: user, to: channel
        clean_buffer()
        send_message "!run repl runreplexe", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/done/i)
      end

      it 'accepts parameters to be supplied' do
        send_message "!repl runreplexe2", from: user, to: channel
        send_message "puts \"result:\#{param}\"", from: user, to: channel
        send_message "bye", from: user, to: channel
        clean_buffer()
        send_message "!run repl runreplexe2 PARAM='xxxx'", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/xxxx/i)
      end

      it 'cannot run a private repl of another person' do
        send_message "!private repl runreplexePrivate", from: :user2, to: channel
        send_message "puts 'done'", from: :user2, to: channel
        send_message "bye", from: :user2, to: channel
        clean_buffer()
        send_message "!run repl runreplexePrivate", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/done/i)
        sleep 1
        expect(buffer(to: channel, from: :ubot).join).to match(/The REPL with session name: runreplexePrivate is private/)
      end


    end
end
  