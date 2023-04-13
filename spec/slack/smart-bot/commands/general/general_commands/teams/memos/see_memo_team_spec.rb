
RSpec.describe SlackSmartBot, "see_memo_team" do
  describe "see memo team" do

    describe "on external channel" do
      channel = :cexternal
      user = :uadmin
      before(:all) do
        send_message "add team example dev <@#{USER1}> <@#{USER2}> <@UXXXXXXXX> members <##{CEXTERNAL}|external_channel> contact_us <##{CEXTERNAL}|external_channel> : beautiful info", from: user , to: channel
        send_message "add team example2 dev <@#{USER1}> <@#{USER2}> <@UXXXXXXXX> members <##{CEXTERNAL}|external_channel> contact_us <##{CEXTERNAL}|external_channel> : beautiful info", from: user , to: channel
        send_message "add memo to example team : some memo text", from: :uadmin, to: channel
        send_message "team example memo 1 my first comment", from: :uadmin, to: channel
        send_message "add private bug to example team testing : some private bug testing text", from: :uadmin, to: channel
        send_message "team example memo 2 my first private comment", from: :uadmin, to: channel
        send_message "add personal bug to example team testing : some personal bug testing text", from: :uadmin, to: channel
        send_message "team example memo 3 my first personal comment", from: :uadmin, to: channel
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
        send_message "#{team_name} team memo 1", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Team \*#{team_name}\* does not exist/i)
        send_message "team #{team_name} memo 1", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Team \*#{team_name}\* does not exist/i)
      end
      
      it "displays error message if no memos" do
        team_name = 'example2'
        send_message "team #{team_name} memo 1", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/There are no memos in team \*#{team_name}\*/i)
        send_message "#{team_name} team memo 1", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/There are no memos in team \*#{team_name}\*/i)
      end

      it "displays error message if memo doesn't exist" do
        team_name = 'example'
        send_message "team #{team_name} memo 100", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Memo \*100\* does not exist in team \*#{team_name}\*/i)
      end

      it 'displays comments' do
        team_name = 'example'
        send_message "team #{team_name} memo 1", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Team #{team_name} memo 1/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/Some memo text/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/my first comment/i)
      end

      it 'displays comments if on channel member and private' do
        team_name = 'example'
        send_message "team #{team_name} memo 2", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Team #{team_name} memo 2/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/some private bug testing text/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/my first private comment/i)
      end

      it "doesn't display comments if on channel member and personal" do
        team_name = 'example'
        send_message "team #{team_name} memo 3", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/Team #{team_name} memo 3/i)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/some personal bug testing text/i)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/my first personal comment/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/This memo is private or personal and you don't have access to it on this channel/i)
      end

      it "doesn't display comments if not on channel member and private" do
        team_name = 'example'
        send_message "team #{team_name} memo 2", from: user, to: :cext1
        expect(buffer(to: :cext1, from: :ubot).join).not_to match(/Team #{team_name} memo 2/i)
        expect(buffer(to: :cext1, from: :ubot).join).not_to match(/some private bug testing text/i)
        expect(buffer(to: :cext1, from: :ubot).join).not_to match(/my first private comment/i)
        expect(buffer(to: :cext1, from: :ubot).join).to match(/This memo is private or personal and you don't have access to it on this channel/i)
      end

      it "displays comments if on DM and personal" do
        team_name = 'example'
        dest = DIRECT.uadmin.ubot
        send_message "team #{team_name} memo 3", from: user, to: dest
        expect(buffer(to: dest, from: :ubot).join).to match(/Team #{team_name} memo 3/i)
        expect(buffer(to: dest, from: :ubot).join).to match(/some personal bug testing text/i)
        expect(buffer(to: dest, from: :ubot).join).to match(/my first personal comment/i)
      end

      it "doesn't display comments if on DM and personal and not the user" do
        team_name = 'example'
        dest = DIRECT.user1.ubot
        send_message "team #{team_name} memo 3", from: :user1, to: dest
        expect(buffer(to: dest, from: :ubot).join).not_to match(/Team #{team_name} memo 3/i)
        expect(buffer(to: dest, from: :ubot).join).not_to match(/some personal bug testing text/i)
        expect(buffer(to: dest, from: :ubot).join).not_to match(/my first personal comment/i)
        expect(buffer(to: dest, from: :ubot).join).to match(/This memo is private or personal and you don't have access to it on this channel/i)
      end


    end
  end
end
