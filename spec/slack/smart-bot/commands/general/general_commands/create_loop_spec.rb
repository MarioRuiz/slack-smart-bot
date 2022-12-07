RSpec.describe SlackSmartBot, "create_loop" do
  describe "create loop" do
    describe "on bot1cm" do
      channel = :cbot1cm
      user = :uadmin

      it "is not possible to create a loop over 24 times" do
        send_message "for 25 times every 10s !ruby puts Time.now", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/You can't do that. Maximum times is 24, minimum every is 10 seconds, maximum every is 60 minutes/i)
      end
      it "is not possible to create a loop under 10 seconds" do
        send_message "for 10 times every 9s !ruby puts Time.now", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/You can't do that. Maximum times is 24, minimum every is 10 seconds, maximum every is 60 minutes/i)
      end
      it "is not possible to create a loop over 60 minutes" do
        send_message "for 10 times every 61m !ruby puts Time.now", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/You can't do that. Maximum times is 24, minimum every is 10 seconds, maximum every is 60 minutes/i)
      end
      it 'is possible to create a loop with "for"' do
        send_message "for 2 times every 10s !which rules", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+ started/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+\* \(1\/2\)/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/bot1cm/i)
        sleep 10
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+\* \(2\/2\)/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/bot1cm/i)
      end
      it 'is possible to create a loop without "for"' do
        send_message "1 times every 10s !which rules", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+ started/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+\* \(1\/1\)/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/bot1cm/i)
      end
      it 'is possible to create a loop with "s"' do
        send_message "1 times every 10s !which rules", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+ started/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+\* \(1\/1\)/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/bot1cm/i)
      end
      it 'is possible to create a loop with "sc"' do
        send_message "1 times every 10sc !which rules", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+ started/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+\* \(1\/1\)/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/bot1cm/i)
      end
      it 'is possible to create a loop with "second"' do
        send_message "1 times every 10 second !which rules", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+ started/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+\* \(1\/1\)/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/bot1cm/i)
      end
      it 'is possible to create a loop with "seconds"' do
        send_message "1 times every 10 seconds !which rules", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+ started/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+\* \(1\/1\)/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/bot1cm/i)
      end
      it 'is possible to create a loop with "m"' do
        send_message "1 times every 1m !which rules", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+ started/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+\* \(1\/1\)/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/bot1cm/i)
      end
      it 'is possible to create a loop with "minute"' do
        send_message "1 times every 1 minute !which rules", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+ started/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+\* \(1\/1\)/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/bot1cm/i)
      end
      it 'is possible to create a loop with "minutes"' do
        send_message "1 times every 1 minutes !which rules", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+ started/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/Loop \d+\* \(1\/1\)/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/bot1cm/i)
      end
    end
  end
end
