
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
      
      it "is not possible to delete a memo if id doesn't exist" do
        send_message "delete memo 2 from example team", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like there is no memo with id 2/)
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
      
    end
  end
end
