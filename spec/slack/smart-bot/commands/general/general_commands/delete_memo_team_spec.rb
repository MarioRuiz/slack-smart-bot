
RSpec.describe SlackSmartBot, "delete_memo_team" do
  describe "delete memo team" do
    describe "on external channel" do
      channel = :cexternal
      user = :uadmin

      before(:each) do
        send_message "delete team example", from: user , to: channel
        send_message "yes", from: user , to: channel
        send_message "add team example members <##{CEXTERNAL}|external_channel> dev <@#{USER1}> : info", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The \*example\* team has been added/i)
        send_message "add memo to example team : some text", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been added to \*example\* team/)
        send_message "add personal memo to example team : some personal text", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been added to \*example\* team/)
      end

      after(:all) do
        send_message "delete team example", from: user , to: channel
        send_message "yes", from: user , to: channel
      end

      it "is not possible to delete a memo if the team doesn't exist" do
        send_message "delete memo 1 from wrongteam team", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like the team \*wrongteam\* doesn't exist/)
      end      

      it "is not possible to delete a memo if the user is not a member of the team or a master admin" do
        send_message "delete memo 1 from example team", from: :user2, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/You have to be a member of the team or a Master admin to be able to delete a memo of the team/)
      end

      it "is not possible to delete a personal memo if not the creator" do
        send_message "delete memo 2 from example team", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Only the creator can delete a personal memo/)
      end
      
      it "is not possible to delete a memo if id doesn't exist" do
        send_message "delete memo 9 from example team", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like there is no memo with id 9/)
      end

      it "is possible to cancel deletion" do
        send_message "delete memo 1 from example team", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/do you really want to delete the memo/)
        send_message "no", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Ok, the memo was not deleted/)        
      end

      it "is possible to delete a memo" do
        send_message "delete memo 1 from example team", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/do you really want to delete the memo/)
        send_message "yes", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been deleted/)        
      end

      it "is possible to delete a personal memo if creator" do
        send_message "delete memo 2 from example team", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/do you really want to delete the memo/)
        send_message "yes", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been deleted/)        
      end
      
      it 'displays a memo that has been deleted if it is the user that created it' do
        send_message "delete memo 1 from example team", from: :user1, to: channel
        send_message "yes", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been deleted/)        
        send_message "team example memo 1", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/This memo was deleted from the team example/)
        expect(buffer(to: channel, from: :ubot).join).to match(/Only the creator \(smartbotuser1\) of the memo can get access to it/)
        expect(buffer(to: channel, from: :ubot).join).to match(/Memo 1 \(memo\): some text/)
      end

      it "doesn't display a memo that has been deleted if it is not the user that created it" do
        send_message "delete memo 1 from example team", from: :user1, to: channel
        send_message "yes", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been deleted/)        
        send_message "team example memo 1", from: :user2, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/This memo was deleted from the team example/)
        expect(buffer(to: channel, from: :ubot).join).to match(/Only the creator \(smartbotuser1\) of the memo can get access to it/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/Memo 1 \(memo\): some text/)
      end

    end
  end
end
