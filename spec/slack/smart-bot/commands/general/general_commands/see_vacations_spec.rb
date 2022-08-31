
RSpec.describe SlackSmartBot, "see_vacations" do
  describe "see vacations" do
    describe "on external channel" do
      channel = :cexternal
      user = :uadmin

      before(:all) do
        send_message "add sick 2031/09/01", from: user , to: channel
        send_message "add vacation 2021/08/01", from: user , to: channel
        send_message "add vacation from 2032/10/01 to 2032/12/01", from: user , to: channel
        send_message "add sick from 2022/01/01 to 2022/01/10", from: user , to: channel
      end
      after(:all) do
        send_message "delete vacation 1", from: user , to: channel
        send_message "delete vacation 2", from: user , to: channel
        send_message "delete vacation 3", from: user , to: channel
        send_message "delete vacation 4", from: user , to: channel
      end

      it 'is displaying time off correctly when calling see my vacations' do
        send_message "see my vacations", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Current and future periods\*\s+:palm_tree:\s+2032\/10\/01\s+->\s+2032\/12\/01\s+#\d\s+:face_with_thermometer:\s+2031\/09\/01/im)
        expect(bufferc(to: channel, from: :ubot).join).to match(/\*Past periods\*\s+:face_with_thermometer:\s+2022\/01\/01\s+->\s+2022\/01\/10\s+#\d\s+:palm_tree:\s+2021\/08\/01/im)
      end

      it 'is displaying time off correctly when calling see my time off' do
        send_message "see my time off", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Current and future periods\*\s+:palm_tree:\s+2032\/10\/01\s+->\s+2032\/12\/01\s+#\d\s+:face_with_thermometer:\s+2031\/09\/01/im)
        expect(bufferc(to: channel, from: :ubot).join).to match(/\*Past periods\*\s+:face_with_thermometer:\s+2022\/01\/01\s+->\s+2022\/01\/10\s+#\d\s+:palm_tree:\s+2021\/08\/01/im)
      end

      it 'is displaying time off correctly when calling see time off @USER' do
        send_message "see time off <@#{UADMIN}>", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Current and future periods\*\s+:beach_with_umbrella:\s+2032\/10\/01\s+->\s+2032\/12\/01\s+#\d\s+:beach_with_umbrella:\s+2031\/09\/01/im)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/\*Past periods\*\s+:beach_with_umbrella:\s+2022\/01\/01\s+->\s+2022\/01\/10\s+#\d\s+:beach_with_umbrella:\s+2021\/08\/01/im)
      end

      it 'is displaying no time off added when see my vacations' do
        send_message "see my vacations", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/You didn't add any time off yet/i)
      end

      it 'is displaying no time off added when see vacations @USER' do
        send_message "see time off <@#{USER1}>", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/No time off added yet for/i)
      end

    end


  end
end
