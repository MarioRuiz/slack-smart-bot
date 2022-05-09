
RSpec.describe SlackSmartBot, "allow_access" do
  describe "allow access" do
    describe "on direct message" do
      channel = DIRECT.uadmin.ubot
      user = :uadmin
    
      it "is not allowed" do
        send_message "allow access echo", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/This command cannot be called from a DM/i)
      end
    end

    describe "on bot" do
      channel = :cbot1cm

      before(:each) do
        send_message "deny access echo", from: :uadmin, to: channel
        clean_buffer()
      end

      after(:all) do
        send_message "allow access echo", from: :uadmin, to: channel
      end
      
      it "is not possible to allow access to unknown command id" do
        send_message "allow access pepe", from: :uadmin, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/It seems like pepe is not valid/)
      end

      it "is not not possible to allow access if you are not an admin" do
        send_message "allow access echo", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Only admins of this channel can use this command. Take a look who is an admin of this channel by calling `see admins`/i)
      end

      it "is not not possible to change access of not allowed commands" do
        send_message "allow access hi_bot", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Sorry but the access for `hi_bot` cannot be changed./i)
      end

      it 'is detecting wrong user name' do
        send_message "allow access echo XXXXXX", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Hmm, I've done some research on this and it looks like XXXXXX is not a valid Slack user/i)
      end

      it 'gives access to all users' do
        send_message '!echo a', from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/You don't have access to use this command, please contact an Admin to be able to use it./i)
        send_message 'allow access echo', from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/All users will have access to this command on this channel/i)
      end

      it 'gives access to specified user' do
        send_message '!echo a', from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/You don't have access to use this command, please contact an Admin to be able to use it./i)
        send_message "allow access echo <@#{UADMIN}>", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/These users will have access to this command on this channel: <@#{UADMIN_NAME}>/i)
      end      
    end

    describe "on external channel" do
      channel = :cexternal

      before(:each) do
        send_message "deny access cls", from: :uadmin, to: channel
        clean_buffer()
      end

      after(:all) do
        send_message "allow access cls", from: :uadmin, to: channel
      end
      
      it "is not possible to allow access to unknown command id" do
        send_message "allow access pepe", from: :uadmin, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/It seems like pepe is not valid/)
      end

      it "is not not possible to allow access if you are not an admin" do
        send_message "allow access cls", from: :user2, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Only admins of this channel can use this command. Take a look who is an admin of this channel by calling `see admins`/i)
      end

      it "is not not possible to change access of not allowed commands" do
        send_message "allow access hi_bot", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Sorry but the access for `hi_bot` cannot be changed./i)
      end

      it 'is detecting wrong user name' do
        send_message "allow access cls XXXXXX", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Hmm, I've done some research on this and it looks like XXXXXX is not a valid Slack user/i)
      end

      it 'gives access to all users' do
        send_message 'cls', from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/You don't have access to use this command, please contact an Admin to be able to use it./i)
        send_message 'allow access cls', from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/All users will have access to this command on this channel/i)
      end

      it 'gives access to all users if creator of channel' do
        send_message 'cls', from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/You don't have access to use this command, please contact an Admin to be able to use it./i)
        send_message 'allow access cls', from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/All users will have access to this command on this channel/i)
      end

      it 'gives access to specified user' do
        send_message 'cls', from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/You don't have access to use this command, please contact an Admin to be able to use it./i)
        send_message "allow access cls <@#{UADMIN}>", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/These users will have access to this command on this channel: <@#{UADMIN_NAME}>/i)
      end
    end

    describe "on extended" do
      channel = :cext1

      before(:each) do
        send_message "deny access echo", from: :uadmin, to: channel
        clean_buffer()
      end

      after(:all) do
        send_message "allow access echo", from: :uadmin, to: channel
      end
      
      it "is not possible to allow access to unknown command id" do
        send_message "allow access pepe", from: :uadmin, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/It seems like pepe is not valid/)
      end

      it "is not not possible to allow access if you are not an admin" do
        send_message "allow access echo", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Only admins of this channel can use this command. Take a look who is an admin of this channel by calling `see admins`/i)
      end

      it "is not not possible to change access of not allowed commands" do
        send_message "allow access hi_bot", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Sorry but the access for `hi_bot` cannot be changed./i)
      end

      it 'is detecting wrong user name' do
        send_message "allow access echo XXXXXX", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Hmm, I've done some research on this and it looks like XXXXXX is not a valid Slack user/i)
      end

      it 'gives access to all users' do
        send_message '!echo a', from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/You don't have access to use this command, please contact an Admin to be able to use it./i)
        send_message 'allow access echo', from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/All users will have access to this command on this channel/i)
      end

      it 'gives access to specified user' do
        send_message '!echo a', from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/You don't have access to use this command, please contact an Admin to be able to use it./i)
        send_message "allow access echo <@#{UADMIN}>", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/These users will have access to this command on this channel: <@#{UADMIN_NAME}>/i)
      end
    end


  end
end
