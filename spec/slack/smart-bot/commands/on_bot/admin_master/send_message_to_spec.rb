
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
    end
  
  end
  