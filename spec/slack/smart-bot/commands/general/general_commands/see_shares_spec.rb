
RSpec.describe SlackSmartBot, "see_shares" do
  describe "see shares" do
    describe "on public channel" do

      it "see shares" do
        send_message "share messages 'example1' on #bot2cu", from: :user1, to: :cbot1cm
        resp = bufferc(to: :cbot1cm, from: :ubot).join
        num = resp.scan(/id:(\d+)\s/).join
        expect(resp).to match(/id:#{num} Messages 'example1' will be shared from now on. Related commands `see shares`, `delete share ID`/i)
        send_message "see shares", from: :user1, to: :cbot1cm
        resp = buffer(to: :cbot1cm, from: :ubot, all: true).join
        expect(resp).to match(/#{num} \:abc\: \*_\d+\/\d+\/\d+_\* \d\d:\d\d \*smartbotuser1\* <#CN1EFTKQB|bot2cu> :\s+`'example1'`/im)        
      end
      
      it "displays There are no active shares right now" do
        send_message "see shares", from: :user1, to: :cexternal
        resp = buffer(to: :cexternal, from: :ubot, all: true).join
        expect(resp).to match(/There are no active shares right now/i)        
      end


    end

  end
end
