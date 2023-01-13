
RSpec.describe SlackSmartBot, "send_message_to" do
    describe "on channel bot" do
      channel = :cbot1cm
      user = :uadmin

      it "is not allowed" do
        send_message "send message to @user1: message example", from: user, to: channel
        message = "Only master admin users on a private conversation with the SmartBot can send messages as SmartBot"
        expect(buffer(to: channel, from: :ubot).join).to match(/#{message}/)
      end
    end
  
    describe "on direct message" do
      channel = DIRECT.uadmin.ubot
      user = :uadmin

      it "is not allowed if not user admin" do
        send_message "send message to @user1: message example", from: :user1, to: DIRECT.user1.ubot
        message = "Only master admin users on a private conversation with the SmartBot can send messages as SmartBot"
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/#{message}/)
      end
      
      it "send message to user" do
        send_message "send message to <@#{USER1}>: message example", from: user, to: channel
        expect(bufferc(to: DIRECT.user1.ubot, from: :ubot).join).to match(/message example/)
      end

      it "send message to multiple users" do
        send_message "send message to  <@#{USER1}>   <@#{USER2}>   : message example", from: user, to: channel
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/message example/)
        expect(buffer(to: DIRECT.user2.ubot, from: :ubot).join).to match(/message example/)
      end

      it "send message to channel" do
        send_message "send message to <#bot1cm|channel_name>: message example", from: user, to: channel
        expect(bufferc(to: :cbot1cm, from: :ubot).join).to match(/message example/)
      end

      it "send message to multiple channels" do
        send_message "send message to <#bot1cm|channel_name>   <#bot2cu|channel_name>  : message example", from: user, to: channel
        expect(buffer(to: :cbot1cm, from: :ubot).join).to match(/message example/)
        expect(buffer(to: :cbot2cu, from: :ubot).join).to match(/message example/)
      end

      it "send message to thread using url" do
        send_message "send message to  https://mario-ruiz.slack.com/archives/CN0595D50/p1632411703000500: message example", from: user, to: channel
        expect(bufferc(to: :cbot1cm, from: :ubot).join).to match(/:on_thread:message example/)
      end

    # helpadmin: `send message to users from YYYY/MM/DD to YYYY/MM/DD #CHANNEL COMMAND_ID: MESSAGE`
    # helpadmin:    In case from and to specified will send a DM to all users that have been using the SmartBot according to the SmartBot Stats. One message every 5sc. #CHANNEL and COMMAND_ID are optional filters.
      it "send message to users from YYYY/MM/DD to YYYY/MM/DD: MESSAGE" do
        send_message "bye bot", from: :user1, to: DIRECT.user1.ubot
        send_message "bye bot", from: :user2, to: DIRECT.user2.ubot
        send_message "send message to users from 2020/01/01 to 2033/01/01: message stats example", from: user, to: channel
        sleep 10
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/message stats example/)
        expect(buffer(to: DIRECT.user2.ubot, from: :ubot).join).to match(/message stats example/)
      end

      it "send message to users from YYYY/MM/DD to YYYY/MM/DD #CHANNEL: MESSAGE" do
        send_message "hi bot", from: :user1, to: :cbot1cm
        send_message "hi bot", from: :user2, to: :cbot1cm
        send_message "send message to users from 2020/01/01 to 2033/01/01 <##{CBOT1CM}|bot1cm>: message stats1 example", from: user, to: channel
        sleep 10
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/message stats1 example/)
        expect(buffer(to: DIRECT.user2.ubot, from: :ubot).join).to match(/message stats1 example/)
      end

      it "doesn't send message to users from YYYY/MM/DD to YYYY/MM/DD #NOT_CHANNEL: MESSAGE" do
        send_message "hi bot", from: :user1, to: :cbot1cm
        send_message "hi bot", from: :user2, to: :cbot1cm
        send_message "send message to users from 2020/01/01 to 2033/01/01 <#xxxxx|bot1cm>: message stats1 example", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/No users selected to send the message/)
      end

      it "send message to users from YYYY/MM/DD to YYYY/MM/DD COMMAND_ID: MESSAGE" do
        send_message "hi bot", from: :user1, to: :cbot1cm
        send_message "hi bot", from: :user2, to: :cbot1cm
        send_message "send message to users from 2020/01/01 to 2033/01/01 hi_bot: message stats2 example", from: user, to: channel
        sleep 7
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/message stats2 example/)
        expect(buffer(to: DIRECT.user2.ubot, from: :ubot).join).to match(/message stats2 example/)
      end

      it "doesn't send message to users from YYYY/MM/DD to YYYY/MM/DD NOT_COMMAND_ID: MESSAGE" do
        send_message "hi bot", from: :user1, to: :cbot1cm
        send_message "hi bot", from: :user2, to: :cbot1cm
        send_message "send message to users from 2020/01/01 to 2033/01/01 hiXX_bot: message stats2 example", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/No users selected to send the message/)
      end
      
      it "doesn't send if No users selected to send the message" do 
        send_message "send message to users from 2010/01/01 to 2015/01/01 <#bot2cu|channel_name>: message stats example", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/No users selected to send the message/)
      end


    end
  
  end
  