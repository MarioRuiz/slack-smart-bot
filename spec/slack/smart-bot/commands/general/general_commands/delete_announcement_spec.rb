
RSpec.describe SlackSmartBot, "delete_announcement" do
  describe "delete announcement" do
    describe "on external channel" do
      it "deletes announcement" do
        send_message "add announcement Example of message", from: :user1, to: :cexternal
        add_buffer = bufferc(to: :cexternal, from: :ubot).join
        num = add_buffer.scan(/id:\s(\d+)\)/).join
        expect(add_buffer).to match(/The announcement has been added/i)
        send_message "delete announcement #{num}", from: :user1, to: :cexternal
        expect(bufferc(to: :cexternal, from: :ubot).join).to match(/The announcement has been deleted/i)
      end
      it "deletes statement" do
        send_message "add announcement Example of message", from: :user1, to: :cexternal
        add_buffer = bufferc(to: :cexternal, from: :ubot).join
        num = add_buffer.scan(/id:\s(\d+)\)/).join
        expect(add_buffer).to match(/The announcement has been added/i)
        send_message "delete statement #{num}", from: :user1, to: :cexternal
        expect(bufferc(to: :cexternal, from: :ubot).join).to match(/The announcement has been deleted/i)
      end
      it "deletes declaration" do
        send_message "add announcement Example of message", from: :user1, to: :cexternal
        add_buffer = bufferc(to: :cexternal, from: :ubot).join
        num = add_buffer.scan(/id:\s(\d+)\)/).join
        expect(add_buffer).to match(/The announcement has been added/i)
        send_message "delete declaration #{num}", from: :user1, to: :cexternal
        expect(bufferc(to: :cexternal, from: :ubot).join).to match(/The announcement has been deleted/i)
      end
      it "deletes message" do
        send_message "add announcement Example of message", from: :user1, to: :cexternal
        add_buffer = bufferc(to: :cexternal, from: :ubot).join
        num = add_buffer.scan(/id:\s(\d+)\)/).join
        expect(add_buffer).to match(/The announcement has been added/i)
        send_message "delete message #{num}", from: :user1, to: :cexternal
        expect(bufferc(to: :cexternal, from: :ubot).join).to match(/The announcement has been deleted/i)
      end
    end
  end
end
