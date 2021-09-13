
RSpec.describe SlackSmartBot, "delete_share" do
  describe "delete share" do
    describe "on public channel" do

      it "delete share" do
        send_message "share messages 'example1' on #bot2cu", from: :user1, to: :cbot1cm
        resp = bufferc(to: :cbot1cm, from: :ubot).join
        num = resp.scan(/id:(\d+)\s/).join
        expect(resp).to match(/id:#{num} Messages 'example1' will be shared from now on. Related commands `see shares`, `delete share ID`/i)
        send_message "delete share #{num}", from: :user1, to: :cbot1cm
        resp = buffer(to: :cbot1cm, from: :ubot).join
        expect(resp).to match(/The share has been deleted: 'example1'/i)        
      end
      it "displays error if id doesn't exist" do
        send_message "delete share 999", from: :user1, to: :cbot1cm
        resp = buffer(to: :cbot1cm, from: :ubot).join
        expect(resp).to match(/Sorry but I didn't find the share id 999/i)        
      end
    end

  end
end
