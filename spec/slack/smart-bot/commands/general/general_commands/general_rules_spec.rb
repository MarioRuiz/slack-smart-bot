
RSpec.describe SlackSmartBot, "general_rules" do
  describe "general rules" do
    describe "direct message" do
      it "responds to normal user in direct message when not using rules" do
        send_message "stop using rules from bot1cm", from: :user1, to: :ubot
        sleep 2
        send_message "echo loveme", from: :user1, to: :ubot
        sleep 2
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/loveme/i)
      end
    end
  end
end
