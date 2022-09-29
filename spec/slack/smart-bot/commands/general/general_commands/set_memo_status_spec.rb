
RSpec.describe SlackSmartBot, "set_memo_status" do
  describe "set memo status" do
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

      it "is not possible to set the status of a memo if the team doesn't exist" do
        send_message "set memo 1 on wrongteam team :runner:", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like the team \*wrongteam\* doesn't exist/)
      end      

      it "is not possible to set the status of a memo if the user is not a member of the team or a master admin" do
        send_message "set memo 1 on example team :runner:", from: :user2, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/You have to be a member of the team or a Master admin to be able to set the status of a memo/)
      end

      it "is not possible to set the status of a personal memo if not the creator" do
        send_message "set memo 2 on example team :runner:", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Only the creator can set the status of a personal memo/)
      end
      
      it "is not possible to set the status of a memo if id doesn't exist" do
        send_message "set memo 9 on example team :runner:", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like there is no memo with id 9/)
      end

      it "is possible to set the status of a memo using 'set memo'" do
        send_message "set memo 1 on example team :runner:", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo status has been updated/)        
        send_message "set memo 1 on team example :runner:", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo status has been updated/)        
      end

      it "is possible to set the status of a memo using 'set STATUS'" do
        send_message "set :runner: on memo 1 example team", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo status has been updated/)        
        send_message "set :runner: on memo 1 team example", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo status has been updated/)        
      end

      it "is possible to set the status of a personal memo if creator" do
        send_message "set memo 2 on example team :runner:", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo status has been updated/)        
      end
      
    end
  end
end
