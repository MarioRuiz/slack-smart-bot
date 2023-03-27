
RSpec.describe SlackSmartBot, "add_memo_team_comment" do
  describe "add memo team comment" do

    describe "on external channel" do
      channel = :cexternal
      user = :uadmin
      before(:all) do
        send_message "add team example dev <@#{USER1}> <@#{USER2}> <@UXXXXXXXX> members <##{CEXTERNAL}|external_channel> contact_us <##{CEXTERNAL}|external_channel> : beautiful info", from: user , to: channel
        send_message "add team example2 dev <@#{USER1}> <@#{USER2}> <@UXXXXXXXX> members <##{CEXTERNAL}|external_channel> contact_us <##{CEXTERNAL}|external_channel> : beautiful info", from: user , to: channel
        send_message "add memo to example team : some memo text", from: :uadmin, to: channel
        clean_buffer()
      end
      after(:all) do
        send_message "delete team example", from: user , to: channel
        send_message "yes", from: user , to: channel
        send_message "delete team example2", from: user , to: channel
        send_message "yes", from: user , to: channel
      end
      it "displays error message if team doesn't exist" do
        team_name = 'xxxxxxxxx'
        send_message "#{team_name} team memo 1 text", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Team \*#{team_name}\* does not exist/i)
        send_message "team #{team_name} memo 1 text", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Team \*#{team_name}\* does not exist/i)
      end
      
      it "displays error message if no memos" do
        team_name = 'example2'
        send_message "team #{team_name} memo 1 text", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/There are no memos in team \*#{team_name}\*/i)
        send_message "#{team_name} team memo 1 text", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/There are no memos in team \*#{team_name}\*/i)
      end

      it "displays error message if memo doesn't exist" do
        team_name = 'example'
        send_message "team #{team_name} memo 100 text", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Memo \*100\* does not exist in team \*#{team_name}\*/i)
      end

      it 'adds a comment to a memo' do
        team_name = 'example'
        send_message "team #{team_name} memo 1 text", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Comment added to memo 1 in team #{team_name}/i)
      end
    end
  end
end
