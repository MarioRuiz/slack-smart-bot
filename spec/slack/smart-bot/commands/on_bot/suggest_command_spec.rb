
RSpec.describe SlackSmartBot, "suggest_command" do

  describe "suggest command" do
    describe "bot channel" do
      channel = :cbot2cu
      it "responds" do
        send_message "suggest command", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Command suggestion/i)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/echo SOMETHING|run something|which rules|go to sleep/i)
        send_message "random command", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Command suggestion/i)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/echo SOMETHING|run something|which rules|go to sleep/i)
        send_message "command suggestion", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Command suggestion/i)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/echo SOMETHING|run something|which rules|go to sleep/i)
        send_message "suggest rule", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Command suggestion/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/echo SOMETHING|run something|which rules|go to sleep/i)
        send_message "random rule", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Command suggestion/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/echo SOMETHING|run something|which rules|go to sleep/i)
        send_message "rule suggestion", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Command suggestion/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/echo SOMETHING|run something|which rules|go to sleep/i)
      end
    end

  
  end
end
