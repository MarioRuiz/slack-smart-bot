
RSpec.describe SlackSmartBot, "add_admin" do
  describe "add admin" do
    describe "on direct message" do
      channel = DIRECT.user1.ubot
      user = :user1
    
      it "is not allowed" do
        send_message "add admin <@#{USER1}>", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/This command cannot be called from a DM/i)
      end
    end

    describe "on bot" do
      channel = :cbot1cm

      after(:each) do
        send_message "remove admin <@#{USER1}>", from: :uadmin , to: channel
        send_message "remove admin <@#{USER2}>", from: :uadmin , to: :cbot2cu
      end
      
      it "is not not possible to add an admin that already is an admin" do
        send_message "add admin <@#{UADMIN}>", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/This user is already an admin of this channel/i)
      end

      it "is not possible to add an admin if you are not admin" do
        send_message "add admin <@#{USER1}>", from: :user1 , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Only the creator of the channel, Master admins or admins can add a new admin for this channel/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>/)
      end

      it "is possible to add an admin if you are an admin" do
        send_message "bot help add admin", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/add admin @user/)
        send_message "add admin <@#{USER1}>", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The user is an admin of this channel from now on./i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>/)
        send_message "bot help add admin", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/add admin @user/)
      end

      it "is possible to add an admin if you are the creator of the channel" do
        send_message "bot help add admin", from: :user2, to: :cbot2cu
        expect(buffer(to: :cbot2cu, from: :ubot).join).not_to match(/add admin @user/)
        send_message "add admin <@#{USER2}>", from: :user1, to: :cbot2cu
        expect(buffer(to: :cbot2cu, from: :ubot).join).to match(/The user is an admin of this channel from now on./i)
        expect(buffer(to: :cbot2cu, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>/)
        send_message "bot help add admin", from: :user2, to: :cbot2cu
        expect(buffer(to: :cbot2cu, from: :ubot).join).to match(/add admin @user/)
      end
    end

    describe "on external channel" do
      channel = :cexternal

      after(:each) do
        send_message "remove admin <@#{USER2}>", from: :uadmin , to: channel
      end
      
      it "is not not possible to add an admin that already is an admin" do
        send_message "add admin <@#{UADMIN}>", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/This user is already an admin of this channel/i)
      end

      it "is not possible to add an admin if you are not admin" do
        send_message "add admin <@#{USER2}>", from: :user2 , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Only the creator of the channel, Master admins or admins can add a new admin for this channel/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>/)
      end

      it "is possible to add an admin if you are an admin" do
        send_message "bot help add admin", from: :user2, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/add admin @user/)
        send_message "add admin <@#{USER2}>", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The user is an admin of this channel from now on./i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>, <@smartbotuser2>/)
        send_message "bot help add admin", from: :user2, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/add admin @user/)
      end

      it "is possible to add an admin if you are the creator of the channel" do
        send_message "bot help add admin", from: :user2, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/add admin @user/)
        send_message "add admin <@#{USER2}>", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The user is an admin of this channel from now on./i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>, <@smartbotuser2>/)
        send_message "bot help add admin", from: :user2, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/add admin @user/)
      end
    end

    describe "on extended" do
      channel = :cext1

      after(:each) do
        send_message "remove admin <@#{USER2}>", from: :uadmin , to: channel
      end
      
      it "is not not possible to add an admin that already is an admin" do
        send_message "add admin <@#{UADMIN}>", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/This user is already an admin of this channel/i)
      end

      it "is not possible to add an admin if you are not admin" do
        send_message "add admin <@#{USER2}>", from: :user2 , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Only the creator of the channel, Master admins or admins can add a new admin for this channel/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>/)
      end

      it "is possible to add an admin if you are an admin" do
        send_message "bot help add admin", from: :user2, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/add admin @user/)
        send_message "add admin <@#{USER2}>", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The user is an admin of this channel from now on./i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser2>/)
        send_message "bot help add admin", from: :user2, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/add admin @user/)
      end
    end


  end
end
