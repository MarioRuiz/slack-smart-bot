
RSpec.describe SlackSmartBot, "see_teams" do
  describe "see teams" do
    describe 'on external and no teams' do
      channel = :cexternal
      user = :uadmin
      it 'displays no teams' do
        send_message "see teams", from: user , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/There are no teams added yet\. Use `add team` command to add a team/i)
      end
    end
    describe "on external channel" do
      channel = :cexternal
      user = :uadmin
      before(:all) do
        send_message "add team example dev <@#{USER1}> <@#{USER2}> <@UXXXXXXXX> members <##{CEXTERNAL}|external_channel> contact_us <##{CEXTERNAL}|external_channel> : beautiful info", from: user , to: channel
        clean_buffer()
      end
      after(:all) do
        send_message "delete team example", from: user , to: channel
        send_message "yes", from: user , to: channel
      end
      it "displays error message if team doesn't exist" do
        team_name = 'xxxxxxxxx'
        send_message "team #{team_name}", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/It seems like the team \*#{team_name}\* doesn't exist/i)
      end
      it 'displays results on a thread when calling see teams' do
        send_message "see teams", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Since there are many lines returned the results are returned on a thread by default/i)
      end
      it 'displays the teams, members, channels and info when calling see teams' do
        send_message "see teams", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Example\*/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/> \*_members_\*/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/> \*_channels_\*/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/>beautiful info/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`dev`_:  user1  \/  user2/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`unassigned`_:  Mario Ruiz Sánchez/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`not on members channel`_:  user2/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`members`_:  <#CP28CTWSD>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`contact_us`_:  <#CP28CTWSD>/i)
      end
      it 'displays the teams, members, channels and info when calling team NAME' do
        send_message "team example", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Example\*/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/> \*_members_\*/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/> \*_channels_\*/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/>beautiful info/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`dev`_:    :large_green_circle: user1,   :white_circle: user2/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`unassigned`_:    :palm_tree: Mario Ruiz Sánchez/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`not on members channel`_:    :white_circle: user2/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`members`_:  <#CP28CTWSD>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`contact_us`_:  <#CP28CTWSD>/i)
      end

      it 'displays no team found when searching for a wrong team' do
        send_message "which team xxxx", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/It seems like we didn't find any team with the criteria supplied/i)        
      end

      it 'displays team found when searching for user' do
        send_message "which team <@#{USER2}>", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Example\*/i)
      end

      it 'displays team found when searching for channel' do
        send_message "which team <##{CEXTERNAL}|external_channel>", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Example\*/i)
      end

      it 'displays team found when searching for info' do
        send_message "which team beautiful", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Example\*/i)
      end

      it "doesn't display user if deleted" do
        send_message "team example", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/userx/i)
        send_message "see teams", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/userx/i)
      end
    end

    #some of the tests has been already added to add_memo_team_spec so we don't test those in here
    describe "memos" do
      channel = :cexternal
      user = :uadmin
      before(:all) do
        send_message "delete team example", from: user , to: channel
        send_message "yes", from: user , to: channel
        send_message "add team example members <##{CEXTERNAL}|external_channel> dev <@#{USER1}> : info", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The \*example\* team has been added/i)
        send_message "add memo to example team : some text", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been added to \*example\* team/)
        send_message "add private memo to example team : some private text", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been added to \*example\* team/)
        send_message "add personal memo to example team : some personal text", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been added to \*example\* team/)
        send_message "add personal memo to example team : some personal admin text", from: :uadmin, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been added to \*example\* team/)
      end

      after(:all) do
        send_message "delete team example", from: user , to: channel
        send_message "yes", from: user , to: channel
        send_message "delete team examplemax", from: user , to: channel
        send_message "yes", from: user , to: channel
      end

      it "displays memos" do
        send_message "team example", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stext\s\(smartbotuser1\s\d+\)/)
      end

      it "doesn't display memos when calling see teams" do
        send_message "see teams", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/some\stext\s\(smartbotuser1\s\d+\)/)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/some\sprivate\s+text\s\(smartbotuser1\s\d+\)\s+`private`/)
      end

      it "displays private memos when on members channel" do
        send_message "team example", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sprivate\s+text\s\(smartbotuser1\s\d+\)\s+`private`/)
      end

      it "doesn't display personal memos when on members channel" do
        send_message "team example", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/`personal`/)
      end

      it "displays private memos when on DM and a member" do
        send_message "team example", from: :user1, to: DIRECT.user1.ubot
        expect(bufferc(to: DIRECT.user1.ubot, from: :ubot).join).to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sprivate\s+text\s\(smartbotuser1\s\d+\)\s+`private`/)
      end

      it "displays personal memos when on DM and the creator but not other personal memos" do
        send_message "team example", from: :user1, to: DIRECT.user1.ubot
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\spersonal\s+text\s\(smartbotuser1\s\d+\)\s+`personal`/)
        expect(bufferc(to: DIRECT.user1.ubot, from: :ubot).join).not_to match(/some\spersonal\s+admin\s+text/)
      end

      it "doesn't display private memos when not on members channel" do
        send_message "team example", from: user, to: :cbot1cm
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/`private`/)
      end

      it "doesn't display personal memos when not on members channel" do
        send_message "team example", from: user, to: :cbot1cm
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/`personal`/)
      end

      it "doesn't display private memos when on DM and not a member" do
        send_message "team example", from: :user2, to: DIRECT.user2.ubot
        expect(bufferc(to: DIRECT.user2.ubot, from: :ubot).join).not_to match(/`private`/)
      end

      it "doesn't display personal memos when on DM and not the creator" do
        send_message "team example", from: :user2, to: DIRECT.user2.ubot
        expect(buffer(to: DIRECT.user2.ubot, from: :ubot).join).not_to match(/`personal`/)
        expect(bufferc(to: DIRECT.user2.ubot, from: :ubot).join).not_to match(/some\spersonal\s+admin\s+text/)
      end

      it 'displays There are too many memos to show when there are more than 10 memos' do
        send_message "add team examplemax members <##{CEXTERNAL}|external_channel> dev <@#{USER1}> : info", from: user, to: channel
        10.times do
          send_message "add memo to examplemax team : some text", from: :user1, to: channel
          expect(bufferc(to: channel, from: :ubot).join).to match(/The memo has been added to \*examplemax\* team/)
        end
        send_message "team examplemax", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/There are too many memos to show/)
      end

    end
    
  end
end
