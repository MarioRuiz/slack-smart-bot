
RSpec.describe SlackSmartBot, "generic" do
    describe "on channel bot" do
      channel = :cbot1cm
      user = :user1

      after(:all) do
        send_message "bye bot", from: user, to: channel
      end
      
      it "responds in all bots when calling on_call for different bots at the same time" do
        command = 'echo A1'
        send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> <##{CBOT2CU}|bot2cu> #{command}", from: user, to: channel
        sleep 2
        expect(buffer(to: channel, from: :ubot).join).to match(/^A1A1$/)
      end
    end
end