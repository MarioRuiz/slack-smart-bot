
RSpec.describe SlackSmartBot, "add_memo_team" do
  describe "add memo team" do
    describe "on external channel" do
      channel = :cexternal
      user = :uadmin

      before(:all) do
        send_message "delete team example", from: user , to: channel
        send_message "yes", from: user , to: channel
        send_message "add team example members <##{CEXTERNAL}|external_channel> dev <@#{USER1}> : info", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The \*example\* team has been added/i)
      end

      after(:all) do
        send_message "delete team example", from: user , to: channel
        send_message "yes", from: user , to: channel
      end
      before(:each) do
        send_message "delete memo 1 from example team", from: user, to: channel
        send_message "yes", from: user, to: channel
      end

      it "is not possible to add a memo if the team doesn't exist" do
        send_message "add memo to wrongteam team : some text", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like the team \*wrongteam\* doesn't exist/)
      end      

      it "is not possible to add a memo if the user is not a member of the team or a master admin" do
        send_message "add memo to example team : some text", from: :user2, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/You have to be a member of the team or a Master admin to be able to add a memo to the team/)
      end

      it "is possible to add a memo if you are a master admin" do
        send_message "add memo to example team : some text", from: :uadmin, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been added to \*example\* team/)
        send_message "team example", from: :uadmin, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stext\s\(marioruizs\s\d+\)/)
      end

      it "is possible to add a memo if you are a team member" do
        send_message "add memo to example team : some text", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been added to \*example\* team/)
        send_message "team example", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stext\s\(smartbotuser1\s\d+\)/)
      end

      it "is possible to add a note" do
        send_message "add note to example team : some text", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been added to \*example\* team/)
        send_message "team example", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/:abc:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stext\s\(smartbotuser1\s\d+\)/)
      end

      it "is possible to add an issue" do
        send_message "add issue to example team : some text", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been added to \*example\* team/)
        send_message "team example", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/:hammer:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stext\s\(smartbotuser1\s\d+\)/)
      end

      it "is possible to add a task" do
        send_message "add task to example team : some text", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been added to \*example\* team/)
        send_message "team example", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/:clock1:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stext\s\(smartbotuser1\s\d+\)/)
      end

      it "is possible to add a feature" do
        send_message "add feature to example team : some text", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been added to \*example\* team/)
        send_message "team example", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/:sunny:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stext\s\(smartbotuser1\s\d+\)/)
      end

      it "is possible to add a bug" do
        send_message "add bug to example team : some text", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been added to \*example\* team/)
        send_message "team example", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stext\s\(smartbotuser1\s\d+\)/)
      end

      it "is possible to add a private memo" do
        send_message "add private memo to example team : some text", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been added to \*example\* team/)
        send_message "team example", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stext\s\(smartbotuser1\s\d+\)\s+`private`/)
      end

      it "is possible to add a personal memo" do
        send_message "add personal memo to example team : some text", from: :user1, to: DIRECT.user1.ubot
        expect(bufferc(to: DIRECT.user1.ubot, from: :ubot).join).to match(/The memo has been added to \*example\* team/)
        send_message "team example", from: :user1, to: DIRECT.user1.ubot
        expect(bufferc(to: DIRECT.user1.ubot, from: :ubot).join).to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stext\s\(smartbotuser1\s\d+\)\s+`personal`/)
      end

      it "is possible to add a topic" do
        send_message "add memo to example team mytopic: some text", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been added to \*example\* team/)
        send_message "team example", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/`mytopic`/)
        expect(bufferc(to: channel, from: :ubot).join).to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stext\s\(smartbotuser1\s\d+\)/)
      end

    end


  end
end
