RSpec.describe SlackSmartBot, "quit_loop" do
    describe "quit loop" do
      describe "on bot1cm" do
        channel = :cbot1cm
        user = :user1

        before(:each) do
            send_message "for 2 times every 10s !which rules", from: user, to: channel
            loopstring = buffer(to: channel, from: :ubot).join
            expect(loopstring).to match(/Loop \d+ started/i)
            @loop_id = loopstring.match(/Loop (\d+) started/i)[1]
        end

        it 'is possible to quit a loop' do
            send_message "quit loop #{@loop_id}", from: user, to: channel
            expect(bufferc(to: channel, from: :ubot).join).to match(/Loop #{@loop_id} stopped/i)
            sleep 11
            expect(bufferc(to: channel, from: :ubot).join).not_to match(/bot1cm/i)
        end
        it 'is possible to stop a loop' do
            send_message "stop loop #{@loop_id}", from: user, to: channel
            expect(bufferc(to: channel, from: :ubot).join).to match(/Loop #{@loop_id} stopped/i)
        end
        it 'is possible to exit a loop' do
            send_message "exit loop #{@loop_id}", from: user, to: channel
            expect(bufferc(to: channel, from: :ubot).join).to match(/Loop #{@loop_id} stopped/i)
        end
        it 'is possible to kill a loop' do
            send_message "kill loop #{@loop_id}", from: user, to: channel
            expect(bufferc(to: channel, from: :ubot).join).to match(/Loop #{@loop_id} stopped/i)
        end
        it 'is possible to quit an iterator' do
            send_message "quit iterator #{@loop_id}", from: user, to: channel
            expect(bufferc(to: channel, from: :ubot).join).to match(/Loop #{@loop_id} stopped/i)
        end
        it 'is possible to quit an iteration' do
            send_message "quit iteration #{@loop_id}", from: user, to: channel
            expect(bufferc(to: channel, from: :ubot).join).to match(/Loop #{@loop_id} stopped/i)
        end
        it 'is possible to quit a loop' do
            send_message "quit loop #{@loop_id}", from: user, to: channel
            expect(bufferc(to: channel, from: :ubot).join).to match(/Loop #{@loop_id} stopped/i)
        end
        it 'is displayed an error if the loop does not exist' do
            send_message "quit loop 999", from: user, to: channel
            expect(bufferc(to: channel, from: :ubot).join).to match(/You don't have any loop with id 999. Only the creator of the loop or an admin can stop the loop./i)
        end
        it 'is possible to quit a loop if admin and not the creator' do
            send_message "quit loop #{@loop_id}", from: :uadmin, to: channel
            expect(bufferc(to: channel, from: :ubot).join).to match(/Loop #{@loop_id} stopped/i)
        end
        it 'is not possible to quit a loop if not creator or admin' do
            send_message "quit loop #{@loop_id}", from: :user2, to: channel
            expect(bufferc(to: channel, from: :ubot).join).to match(/Only the creator of the loop or an admin can stop the loop/i)
        end

      end
    end
end
  