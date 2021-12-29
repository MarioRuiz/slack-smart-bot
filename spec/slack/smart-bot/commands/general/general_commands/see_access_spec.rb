
RSpec.describe SlackSmartBot, "see_access" do
  describe "see access" do
    describe "on bot" do
      channel = :cbot1cm

      before(:each) do
        send_message "allow access echo", from: :uadmin, to: channel
        clean_buffer()
      end

      after(:all) do
        send_message "allow access echo", from: :uadmin, to: channel
      end
      
      it "is not possible to display access to unknown command id" do
        send_message "see access pepe", from: :user1, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/It seems like pepe is not valid/)
      end

      it 'displays that is available for everyone' do
        send_message 'see access echo', from: :user1, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/`echo` seems to be available in this channel/)
      end

      it 'displays that is available for the user specified' do
        send_message "allow access echo <@#{UADMIN}>", from: :uadmin, to: channel
        send_message 'see access echo', from: :user1, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/Only these users have access to `echo` in this channel: <@#{UADMIN_NAME}>/)
      end

      it 'displays that is available for the users specified' do
        send_message "allow access echo <@#{UADMIN}> <@#{USER1}>", from: :uadmin, to: channel
        send_message 'see access echo', from: :user1, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/Only these users have access to `echo` in this channel: <@#{UADMIN_NAME}>, <@smartbotuser1>/)
      end
      it 'displays that is not available' do
        send_message "deny access echo", from: :uadmin, to: channel
        send_message 'see access echo', from: :user1, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/`echo` is not possible to be used in this channel. Please contact an admin if you want to use it./)
      end
    end

    describe "on external channel" do
      channel = :cexternal

      before(:each) do
        send_message "allow access cls", from: :uadmin, to: channel
        clean_buffer()
      end

      after(:all) do
        send_message "allow access cls", from: :uadmin, to: channel
      end
      
      it "is not possible to display access to unknown command id" do
        send_message "see access pepe", from: :user1, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/It seems like pepe is not valid/)
      end

      it 'displays that is available for everyone' do
        send_message 'see access cls', from: :user1, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/`cls` seems to be available in this channel/)
      end

      it 'displays that is available for the user specified' do
        send_message "allow access cls <@#{UADMIN}>", from: :uadmin, to: channel
        send_message 'see access cls', from: :user1, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/Only these users have access to `cls` in this channel: <@#{UADMIN_NAME}>/)
      end

      it 'displays that is available for the users specified' do
        send_message "allow access cls <@#{UADMIN}> <@#{USER1}>", from: :uadmin, to: channel
        send_message 'see access cls', from: :user1, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/Only these users have access to `cls` in this channel: <@#{UADMIN_NAME}>, <@smartbotuser1>/)
      end
      it 'displays that is not available' do
        send_message "deny access cls", from: :uadmin, to: channel
        send_message 'see access cls', from: :user1, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/`cls` is not possible to be used in this channel. Please contact an admin if you want to use it./)
      end
    end

    describe "on extended" do
      channel = :cext1

      before(:each) do
        send_message "allow access echo", from: :uadmin, to: channel
        clean_buffer()
      end

      after(:all) do
        send_message "allow access echo", from: :uadmin, to: channel
      end
      
      it "is not possible to display access to unknown command id" do
        send_message "see access pepe", from: :user1, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/It seems like pepe is not valid/)
      end

      it 'displays that is available for everyone' do
        send_message 'see access echo', from: :user1, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/`echo` seems to be available in this channel/)
      end

      it 'displays that is available for the user specified' do
        send_message "allow access echo <@#{UADMIN}>", from: :uadmin, to: channel
        send_message 'see access echo', from: :user1, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/Only these users have access to `echo` in this channel: <@#{UADMIN_NAME}>/)
      end

      it 'displays that is available for the users specified' do
        send_message "allow access echo <@#{UADMIN}> <@#{USER1}>", from: :uadmin, to: channel
        send_message 'see access echo', from: :user1, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/Only these users have access to `echo` in this channel: <@#{UADMIN_NAME}>, <@smartbotuser1>/)
      end
      it 'displays that is not available' do
        send_message "deny access echo", from: :uadmin, to: channel
        send_message 'see access echo', from: :user1, to: channel
        expect(buffer(to:channel, from: :ubot).join).to match(/`echo` is not possible to be used in this channel. Please contact an admin if you want to use it./)
      end

    end


  end
end
