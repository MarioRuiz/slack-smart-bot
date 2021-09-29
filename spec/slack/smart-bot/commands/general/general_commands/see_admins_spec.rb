
RSpec.describe SlackSmartBot, "see_admins" do
  describe "see admins" do
    describe "on direct message" do
      channel = DIRECT.uadmin.ubot

      before(:all) do 
        send_message "add admin <@#{USER2}>", from: :uadmin , to: :cbot1cm
        expect(buffer(to: :cbot1cm, from: :ubot).join).to match(/The user is an admin of this channel from now on/i)
        expect(buffer(to: :cbot1cm, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser2>/)
        send_message "use #bot1cm", from: :uadmin , to: channel
        sleep 1
      end

      after(:all) do
        send_message "remove admin <@#{USER2}>", from: :uadmin , to: :cbot1cm
        send_message "stop using #bot1cm", from: :uadmin , to: channel
      end
      
      it "displays channel creator" do
        send_message "see admins", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Channel creator\*: <@#{UADMIN}>/i)
      end
      it "displays master admins" do
        send_message "see admins", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Master admins\*: <@marioruizs>/i)
      end
      it "displays admins" do
        send_message "see admins", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@smartbotuser2>/i)
      end
    end

    describe "on bot" do
      channel = :cbot2cu

      before(:all) do 
        send_message "add admin <@#{USER2}>", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The user is an admin of this channel from now on/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>, <@smartbotuser2>/)
      end

      after(:all) do
        send_message "remove admin <@#{USER2}>", from: :uadmin , to: channel
      end
      
      it "displays channel creator" do
        send_message "see admins", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Channel creator\*: <@#{USER1}>/i)
      end
      it "displays master admins" do
        send_message "see admins", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Master admins\*: <@marioruizs>/i)
      end
      it "displays admins" do
        send_message "see admins", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@smartbotuser2>/i)
      end

    end

    describe "on external channel" do
      channel = :cexternal

      before(:all) do 
        send_message "add admin <@#{USER2}>", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The user is an admin of this channel from now on/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser1>, <@smartbotuser2>/)
      end

      after(:all) do
        send_message "remove admin <@#{USER2}>", from: :uadmin , to: channel
      end
      
      it "displays channel creator" do
        send_message "see admins", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Channel creator\*: <@#{USER1}>/i)
      end
      it "displays master admins" do
        send_message "see admins", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Master admins\*: <@marioruizs>/i)
      end
      it "displays admins" do
        send_message "see admins", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@smartbotuser2>/i)
      end
    end

    describe "on extended" do
      channel = :cext1

      before(:all) do 
        send_message "add admin <@#{USER2}>", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The user is an admin of this channel from now on/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@marioruizs>, <@smartbotuser2>/)
      end

      after(:all) do
        send_message "remove admin <@#{USER2}>", from: :uadmin , to: channel
      end
      
      it "displays channel creator" do
        send_message "see admins", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Channel creator\*: <@#{UADMIN}>/i)
      end
      it "displays master admins" do
        send_message "see admins", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Master admins\*: <@marioruizs>/i)
      end
      it "displays admins" do
        send_message "see admins", from: :uadmin , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Admins\*: <@smartbotuser2>/i)
      end
    end


  end
end
