
RSpec.describe SlackSmartBot, "add_announcement" do
  describe "add announcement" do
    describe "on external channel" do
      it "responds to add announcement MESSAGE" do
        send_message "add announcement Example of message", from: :user1, to: :cexternal
        expect(buffer(to: :cexternal, from: :ubot).join).to match(/The announcement has been added/i)
      end
      it "responds to add statement MESSAGE" do
        send_message "add statement Example of message", from: :user1, to: :cexternal
        expect(buffer(to: :cexternal, from: :ubot).join).to match(/The announcement has been added/i)
      end
      it "responds to add message MESSAGE" do
        send_message "add message Example of message", from: :user1, to: :cexternal
        expect(buffer(to: :cexternal, from: :ubot).join).to match(/The announcement has been added/i)
      end
      it "responds to add declaration MESSAGE" do
        send_message "add declaration Example of message", from: :user1, to: :cexternal
        expect(buffer(to: :cexternal, from: :ubot).join).to match(/The announcement has been added/i)
      end
      it "responds to add red announcement MESSAGE" do
        send_message "add red announcement Example of message", from: :user1, to: :cexternal
        expect(buffer(to: :cexternal, from: :ubot).join).to match(/The announcement has been added/i)
      end
      it "responds to add green announcement MESSAGE" do
        send_message "add green announcement Example of message", from: :user1, to: :cexternal
        expect(buffer(to: :cexternal, from: :ubot).join).to match(/The announcement has been added/i)
      end
      it "responds to add yellow announcement MESSAGE" do
        send_message "add yellow announcement Example of message", from: :user1, to: :cexternal
        expect(buffer(to: :cexternal, from: :ubot).join).to match(/The announcement has been added/i)
      end
      it "responds to add white announcement MESSAGE" do
        send_message "add white announcement Example of message", from: :user1, to: :cexternal
        expect(buffer(to: :cexternal, from: :ubot).join).to match(/The announcement has been added/i)
      end
      it "responds to add EMOJI announcement MESSAGE" do
        send_message "add :green_heart: announcement Example of message", from: :user1, to: :cexternal
        expect(buffer(to: :cexternal, from: :ubot).join).to match(/The announcement has been added/i)
      end
      it "adds announcement as private messages on DM" do
        send_message "add :green_heart: announcement Example of message", from: :uadmin, to: DIRECT.uadmin.ubot
        expect(buffer(to: DIRECT.uadmin.ubot, from: :ubot).join).to match(/The announcement has been added/i)
      end

    end
  end
end
