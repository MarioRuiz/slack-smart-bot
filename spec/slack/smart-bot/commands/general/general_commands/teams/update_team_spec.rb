
RSpec.describe SlackSmartBot, "update_team" do
  describe "update team" do
    describe "on external channel" do
      channel = :cexternal
      user = :uadmin
      before(:all) do
        send_message "add team example dev <@#{USER1}> <@UXXXXXXXX> members <##{CEXTERNAL}|external_channel> contact_us <##{CEXTERNAL}|external_channel> : beautiful info", from: user , to: channel
        clean_buffer()
      end
      after(:all) do
        send_message "delete team example", from: user , to: channel
        send_message "yes", from: user , to: channel
      end
      it "displays error message if team doesn't exist" do
        team_name = 'xxxxxxxxx'
        send_message "update team #{team_name} : beautiful info", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/It seems like the team \*#{team_name}\* doesn't exist/i)
      end

      it "only a member of the team, the creator or a Master admin to be able to update the team" do
        send_message "update team example : beautiful info", from: :user2, to: :cbot2cu
        expect(buffer(to: :cbot2cu, from: :ubot).join).to match(/You have to be a member of the team, the creator or a Master admin to be able to update this team/i)
      end

      it "updates team name" do
        send_message "update team example newexample", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The \*example\* team has been renamed newexample/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Newexample\*/i)
        send_message "update team newexample example", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The \*newexample\* team has been renamed example/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Example\*/i)
      end

      it "updates info" do
        send_message "update team example : new info", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The \*example\* team has been updated/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/new info/i)
      end

      it "adds member type" do
        send_message "update team example add manager <@#{USER1}>", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The \*example\* team has been updated/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`manager`_:    :large_green_circle: user1/i)
      end

      it "adds channel type" do
        send_message "update team example add general <##{CEXTERNAL}|external_channel>", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The \*example\* team has been updated/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`general`_:  <##{CEXTERNAL}>/i)
      end

      it "deletes member type" do
        send_message "update team example add manager <@#{USER1}>", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The \*example\* team has been updated/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`manager`_:    :large_green_circle: user1/i)
        clean_buffer()
        send_message "update team example delete manager <@#{USER1}>", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The \*example\* team has been updated/i)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/_`manager`_:    :large_green_circle: user1/i)
      end

      it "deletes channel type" do
        send_message "update team example add general <##{CEXTERNAL}|external_channel>", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The \*example\* team has been updated/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`general`_:  <##{CEXTERNAL}>/i)
        clean_buffer()
        send_message "update team example delete general <##{CEXTERNAL}|external_channel>", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The \*example\* team has been updated/i)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/_`general`_:  <##{CEXTERNAL}>/i)
      end

      it "deletes member" do
        send_message "update team example add manager <@#{USER2}> love <@#{USER2}> ", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The \*example\* team has been updated/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`manager`_:    :white_circle: user2/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`love`_:    :white_circle: user2/i)
        clean_buffer()
        send_message "update team example delete <@#{USER2}>", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The \*example\* team has been updated/i)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/_`manager`_:    :white_circle: user2/i)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/_`love`_:    :white_circle: user2/i)
      end

      it "deletes channel" do
        send_message "update team example add general <##{CBOT1CM}|bot1cm> love <##{CBOT1CM}|bot1cm>", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The \*example\* team has been updated/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`general`_:  <##{CBOT1CM}>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/_`love`_:  <##{CBOT1CM}>/i)
        clean_buffer()
        send_message "update team example delete <##{CBOT1CM}|bot1cm>", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The \*example\* team has been updated/i)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/_`general`_:  <##{CBOT1CM}>/i)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/_`love`_:  <##{CBOT1CM}>/i)
      end

      it 'can delete an user that has been deactivated' do
        send_message "update team example add manager <@#{USERX}>", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The \*example\* team has been updated/i)
        clean_buffer()
        send_message "update team example delete <@#{USERX}>", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The \*example\* team has been updated/i)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/_`manager`_:    :white_circle: userx/i)
      end

      it 'is detecting wrong channel' do
        send_message "update team example add channel #xxxx", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like the members or channel list is not correct\. Please double check/i)
        send_message "update team example delete channel #xxxx", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like the members or channel list is not correct\. Please double check/i)
        send_message "update team example delete #xxxx", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like the members or channel list is not correct\. Please double check/i)
      end

    end
  end
end
