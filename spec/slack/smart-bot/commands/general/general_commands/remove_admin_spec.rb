
RSpec.describe SlackSmartBot, "remove_admin" do
  describe "remove admin" do
    describe "on direct message" do
      channel = DIRECT.user1.ubot
      user = :user1
    
      it "is not allowed" do
        send_message "remove admin <@#{USER1}>", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/This command cannot be called from a DM/i)
      end
    end

    describe "on bot" do
      channel = :cbot2cu
      
      it "is not not possible to remove the creator of the channel" do
        send_message "remove admin <@#{USER1}>", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/This user created the channel and cannot be removed as an admin/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>/)
      end

      it "is not not possible to remove master admin of the channel" do
        send_message "remove admin <@#{UADMIN}>", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Master admins cannot be removed as admins of this channel/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>/)
      end

      it "displays that the user is not an admin so cannot be removed" do
        send_message "remove admin <@#{USER2}>", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/This user is not an admin of this channel/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>/)
      end

      it "is not possible to remove an admin if you are not admin" do
        send_message "remove admin <@#{USER1}>", from: :user2 , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Only the creator of the channel, Master admins or admins can remove an admin of this channel/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>/)
      end

      it "is possible to remove an admin if you are an admin" do
        send_message "add admin <@#{USER2}>", from: :uadmin, to: channel
        added = bufferc(to: channel, from: :ubot).join
        send_message "remove admin <@#{USER2}>", from: :user2, to: channel
        expect(added).to match(/The user is an admin of this channel from now on./i)
        expect(added).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>, <@smartbotuser2>/)
        expect(buffer(to: channel, from: :ubot).join).to match(/The user is not an admin of this channel from now on/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>/)
      end

      it "is possible to remove an admin if you are the creator of the channel" do
        send_message "add admin <@#{USER2}>", from: :uadmin, to: channel
        added = bufferc(to: channel, from: :ubot).join
        send_message "remove admin <@#{USER2}>", from: :user1, to: channel
        expect(added).to match(/The user is an admin of this channel from now on./i)
        expect(added).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>, <@smartbotuser2>/)
        expect(buffer(to: channel, from: :ubot).join).to match(/The user is not an admin of this channel from now on/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>/)
      end
    end

    describe "on external channel" do
      channel = :cexternal
      
      it "is not not possible to remove the creator of the channel" do
        send_message "remove admin <@#{USER1}>", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/This user created the channel and cannot be removed as an admin/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>/)
      end

      it "is not not possible to remove master admin of the channel" do
        send_message "remove admin <@#{UADMIN}>", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Master admins cannot be removed as admins of this channel/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>/)
      end

      it "displays that the user is not an admin so cannot be removed" do
        send_message "remove admin <@#{USER2}>", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/This user is not an admin of this channel/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>/)
      end

      it "is not possible to remove an admin if you are not admin" do
        send_message "remove admin <@#{USER1}>", from: :user2 , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Only the creator of the channel, Master admins or admins can remove an admin of this channel/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>/)
      end

      it "is possible to remove an admin if you are an admin" do
        send_message "add admin <@#{USER2}>", from: :uadmin, to: channel
        added = bufferc(to: channel, from: :ubot).join
        send_message "remove admin <@#{USER2}>", from: :user2, to: channel
        expect(added).to match(/The user is an admin of this channel from now on./i)
        expect(added).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>, <@smartbotuser2>/)
        expect(buffer(to: channel, from: :ubot).join).to match(/The user is not an admin of this channel from now on/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>/)
      end

      it "is possible to remove an admin if you are the creator of the channel" do
        send_message "add admin <@#{USER2}>", from: :uadmin, to: channel
        added = bufferc(to: channel, from: :ubot).join
        send_message "remove admin <@#{USER2}>", from: :user1, to: channel
        expect(added).to match(/The user is an admin of this channel from now on./i)
        expect(added).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>, <@smartbotuser2>/)
        expect(buffer(to: channel, from: :ubot).join).to match(/The user is not an admin of this channel from now on/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>/)
      end
    end

    describe "on extended" do
      channel = :cext1

      it "is not not possible to remove the creator of the channel" do
        send_message "remove admin <@#{UADMIN}>", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/This user created the channel and cannot be removed as an admin/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>/)
      end

      it "displays that the user is not an admin so cannot be removed" do
        send_message "remove admin <@#{USER2}>", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/This user is not an admin of this channel/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>/)
      end

      it "is not possible to remove an admin if you are not admin" do
        send_message "remove admin <@#{UADMIN}>", from: :user2 , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Only the creator of the channel, Master admins or admins can remove an admin of this channel/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>/)
      end

      it "is possible to remove an admin if you are an admin" do
        send_message "add admin <@#{USER2}>", from: :uadmin, to: channel
        added = bufferc(to: channel, from: :ubot).join
        send_message "remove admin <@#{USER2}>", from: :user2, to: channel
        expect(added).to match(/The user is an admin of this channel from now on./i)
        expect(added).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser2>/)
        expect(buffer(to: channel, from: :ubot).join).to match(/The user is not an admin of this channel from now on/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>/)
      end

    end


  end
end
