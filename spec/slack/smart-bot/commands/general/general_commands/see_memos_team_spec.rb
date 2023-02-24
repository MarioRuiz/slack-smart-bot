
RSpec.describe SlackSmartBot, "see_memos_teams" do
  describe "see memos teams" do
    #some of the tests have been already added to add_memo_team_spec and see_teams_spec so we don't test those in here
    describe 'on external and no teams' do
      channel = :cexternal
      user = :uadmin
      it 'displays no teams' do
        send_message "see memos team xxx", from: user , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/There are no teams added yet\. Use `add team` command to add a team/i)
        send_message "see memos xxx team", from: user , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/There are no teams added yet\. Use `add team` command to add a team/i)
      end
    end

    describe "on external channel" do
      channel = :cexternal
      user = :uadmin
      before(:all) do
        send_message "add team example dev <@#{USER1}> <@#{USER2}> <@UXXXXXXXX> members <##{CEXTERNAL}|external_channel> contact_us <##{CEXTERNAL}|external_channel> : beautiful info", from: user , to: channel
        send_message "add team example2 dev <@#{USER1}> <@#{USER2}> <@UXXXXXXXX> members <##{CEXTERNAL}|external_channel> contact_us <##{CEXTERNAL}|external_channel> : beautiful info", from: user , to: channel
        send_message "add memo to example team : some memo text", from: :uadmin, to: channel
        send_message "add note to example team : some note text", from: :uadmin, to: channel
        send_message "add issue to example team : some issue text", from: :uadmin, to: channel
        send_message "add task to example team : some task text", from: :uadmin, to: channel
        send_message "add feature to example team : some feature text", from: :uadmin, to: channel
        send_message "add bug to example team : some bug text", from: :uadmin, to: channel
        send_message "add bug to example team testing : some bug testing text", from: :uadmin, to: channel
        send_message "add private bug to example team testing : some private bug testing text", from: :uadmin, to: channel
        send_message "add personal bug to example team testing : some personal bug testing text", from: :uadmin, to: channel
        send_message "add memo to example team testing : some memo testing text", from: :uadmin, to: channel
        
        clean_buffer()
      end
      after(:all) do
        send_message "delete team example", from: user , to: channel
        send_message "delete team example2", from: user , to: channel
        send_message "yes", from: user , to: channel
      end
      it "displays error message if team doesn't exist" do
        team_name = 'xxxxxxxxx'
        send_message "see memos team #{team_name}", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/There is no team named #{team_name}/i)
        send_message "see memos #{team_name} team", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/There is no team named #{team_name}/i)
      end
      
      it "displays error message if no memos" do
        team_name = 'example2'
        send_message "see all memos team #{team_name}", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/There are no memos for the team #{team_name}/i)
        send_message "see all memos #{team_name} team", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/There are no memos for the team #{team_name}/i)
      end
      it 'returns no memos after filtering by memo type and no memos returned' do
        team_name = 'example'
        send_message "see jira team #{team_name}", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/There are no memos jira/i)
        send_message "see github #{team_name} team", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/There are no memos github/i)
      end

      it 'returns no memos after filtering by topic and no memos returned' do
        team_name = 'example'
        send_message "see bug team #{team_name} wrong_topic", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/There are no memos bug wrong_topic/i)
        send_message "see bug #{team_name} team wrong_topic", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/There are no memos bug wrong_topic/i)
      end

      it 'returns all memos when calling see all memos' do
        team_name = 'example'
        send_message "see all memos team #{team_name}", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:abc:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\snote\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:hammer:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sissue\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:clock1:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stask\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:sunny:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sfeature\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug testing\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sprivate\sbug\stesting\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stesting\stext/)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\spersonal\sbug\stesting\stext/)

        send_message "see all memos #{team_name} team", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:abc:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\snote\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:hammer:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sissue\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:clock1:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stask\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:sunny:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sfeature\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug testing\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sprivate\sbug\stesting\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stesting\stext/)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\spersonal\sbug\stesting\stext/)
      end

      it 'returns only memos when calling see memos' do
        team_name = 'example'
        send_message "see memos team #{team_name}", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:abc:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\snote\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:hammer:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sissue\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:clock1:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stask\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:sunny:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sfeature\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug testing\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sprivate\sbug\stesting\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stesting\stext/)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\spersonal\sbug\stesting\stext/)
      end

      it 'returns only notes when calling see notes' do
        team_name = 'example'
        send_message "see notes team #{team_name}", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:abc:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\snote\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:hammer:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sissue\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:clock1:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stask\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:sunny:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sfeature\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug testing\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sprivate\sbug\stesting\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stesting\stext/)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\spersonal\sbug\stesting\stext/)
      end

      it 'returns only issues when calling see issues' do
        team_name = 'example'
        send_message "see issues team #{team_name}", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:abc:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\snote\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:hammer:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sissue\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:clock1:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stask\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:sunny:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sfeature\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug testing\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sprivate\sbug\stesting\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stesting\stext/)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\spersonal\sbug\stesting\stext/)
      end

      it 'returns only tasks when calling see tasks' do
        team_name = 'example'
        send_message "see tasks team #{team_name}", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:abc:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\snote\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:hammer:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sissue\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:clock1:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stask\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:sunny:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sfeature\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug testing\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sprivate\sbug\stesting\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stesting\stext/)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\spersonal\sbug\stesting\stext/)
      end

      it 'returns only features when calling see features' do
        team_name = 'example'
        send_message "see features team #{team_name}", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:abc:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\snote\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:hammer:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sissue\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:clock1:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stask\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:sunny:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sfeature\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug testing\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sprivate\sbug\stesting\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stesting\stext/)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\spersonal\sbug\stesting\stext/)
      end

      it 'returns only bugs when calling see bugs' do
        team_name = 'example'
        send_message "see bugs team #{team_name}", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:abc:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\snote\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:hammer:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sissue\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:clock1:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stask\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:sunny:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sfeature\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug testing\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sprivate\sbug\stesting\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stesting\stext/)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\spersonal\sbug\stesting\stext/)
      end

      it 'returns only filtered memos by topic' do
        team_name = 'example'
        send_message "see bugs team #{team_name} testing", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:abc:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\snote\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:hammer:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sissue\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:clock1:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\stask\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:sunny:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sfeature\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sbug testing\stext/)
        expect(buffer(to: channel, from: :ubot).join).to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\sprivate\sbug\stesting\stext/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/:memo:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\smemo\stesting\stext/)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/:bug:\s+\d\d\d\d\/\d\d\/\d\d:\s+:new:\s+some\spersonal\sbug\stesting\stext/)
      end
    end
  end
end
