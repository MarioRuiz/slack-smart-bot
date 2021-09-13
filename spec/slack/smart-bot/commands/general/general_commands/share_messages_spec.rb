
RSpec.describe SlackSmartBot, "share_messages" do
  describe "share messages" do
    describe "on public channel" do

      it "shares when text" do
        send_message "share messages 'example1' on #bot2cu", from: :user1, to: :cbot1cm
        resp = buffer(to: :cbot1cm, from: :ubot).join
        num = resp.scan(/id:(\d+)\s/).join
        expect(resp).to match(/id:#{num} Messages 'example1' will be shared from now on. Related commands `see shares`, `delete share ID`/i)
        send_message "This is just used for example1 It should be shared", from: :user2, to: :cbot1cm
        sleep 2
        resp = buffer(to: :cbot2cu, from: :ubot).join
        expect(resp).to match(/Shared> by <@smartbotuser1> from <#CN0595D50>/i)        
      end

      it "shares when regexp" do
        send_message "share messages /exampLe2/ on #bot2cu", from: :user1, to: :cbot1cm
        resp = buffer(to: :cbot1cm, from: :ubot).join
        num = resp.scan(/id:(\d+)\s/).join
        expect(resp).to match(/id:#{num} Messages \/exampLe2\/ will be shared from now on. Related commands `see shares`, `delete share ID`/i)
        send_message "This is just used for example2 It should be shared", from: :user2, to: :cbot1cm
        resp = buffer(to: :cbot2cu, from: :ubot).join
        expect(resp).to match(/Shared> by <@smartbotuser1> from <#CN0595D50>/i)
      end

      it "cannot share messages on the same channel than source channel" do
        send_message "share messages /exampLe2/ on #bot1cm", from: :user1, to: :cbot1cm
        resp = buffer(to: :cbot1cm, from: :ubot).join
        expect(resp).to match(/cannot share messages on the same channel than source channel/i)
      end
      
      it "SmartBot user and user adding the share need to be members on both channels" do
        send_message "share messages /exampLe2/ on #privextended", from: :user2, to: :cbot1cm
        resp = buffer(to: :cbot1cm, from: :ubot).join
        expect(resp).to match(/The channel #privextended need to exist and the SmartBot and you have to be members/i)
      end

    end

  end
end
