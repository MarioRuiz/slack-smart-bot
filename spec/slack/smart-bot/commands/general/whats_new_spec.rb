
RSpec.describe SlackSmartBot, "whats_new" do
 
  describe "whats_new" do
    describe "bot channel" do
      it "responds to normal user in bot channel" do
        send_message "what's new", from: :user2, to: :cbot2cu
        expect(buffer(to: :cbot2cu, from: :ubot).join).to include('Released')
      end
    end

    describe "direct message" do
      it "responds to normal user in direct message" do
        send_message "what's new", from: :user1, to: :ubot
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to include('Released')
      end
    end

    describe "on extended channel" do
      it "doesn't respond to normal user in extended channel" do
        send_message "!what's new", from: :uadmin, to: :cext1
        expect(buffer(to: :cext1, from: :ubot).join).not_to include('Released')
      end
    end
  end
end
