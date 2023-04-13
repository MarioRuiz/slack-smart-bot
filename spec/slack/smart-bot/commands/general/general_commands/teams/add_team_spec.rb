
RSpec.describe SlackSmartBot, "add_team" do
  describe "add team" do
    describe "on external channel" do
      channel = :cexternal
      user = :uadmin

      before(:each) do
        send_message "delete team example", from: user , to: channel
        send_message "yes", from: user , to: channel
      end
      after(:all) do
        send_message "delete team example", from: user , to: channel
        send_message "yes", from: user , to: channel
      end

      it 'is not possible to add a team if the team already exists' do
        send_message "add team example dev <@#{USER1}> : info", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The \*example\* team has been added/i)
        send_message "add team example dev <@#{USER1}> : info", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like the team \*example\* already exists/i)
      end

      it 'is necessary to specify a member type' do
        send_message "add team example <@#{USER1}> : info", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/You need to specify the TYPE for the member/i)
      end
      
      it 'is necessary to specify a channel type' do
        send_message "add team example <##{CEXTERNAL}|external_channel> : info", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/You need to specify the TYPE for the channel/i)
      end

      it 'is necessary to have the smarbot as a channel member' do
        send_message "add team example members <##{CBOTNOTINVITED}|channel_bot_not_invited> : info", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Add the Smart Bot to \*<#CNM7T8G8P>\* channel first/i)
      end
      
      it 'is detecting wrong parameters' do
        send_message "add team example wrong : info", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like the parameters supplied are not correct\. Please double check/i)
      end

      it 'is detecting wrong channel' do
        send_message "add team example channel #xxxx : info", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like the members or channel list is not correct\. Please double check/i)
      end

      it 'is detecting wrong user' do
        send_message "add team example user @user : info", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like the members or channel list is not correct\. Please double check/i)
      end

      it 'is possible to add a team supplying a member type' do
        send_message "add team example dev <@#{USER1}> <@#{USER2}> : info", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The \*example\* team has been added/i)
      end

      it 'is possible to add a team supplying a members channel' do
        send_message "add team example members <##{CEXTERNAL}|external_channel> : info", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The \*example\* team has been added/i)
      end

      it 'is possible to add a team supplying a members channel and channels info' do
        send_message "add team example members <##{CEXTERNAL}|external_channel> contact_us <##{CEXTERNAL}|external_channel> : info", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The \*example\* team has been added/i)
      end

      it 'is possible to add a team supplying a member type and channels info' do
        send_message "add team example dev <@#{USER1}> <@#{USER2}> contact_us <##{CEXTERNAL}|external_channel> : info", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The \*example\* team has been added/i)
      end

      it 'is possible to add a team supplying a members channel and member type' do
        send_message "add team example members <##{CEXTERNAL}|external_channel> dev <@#{USER1}> <@#{USER2}> : info", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/The \*example\* team has been added/i)
      end
      
    end


  end
end
