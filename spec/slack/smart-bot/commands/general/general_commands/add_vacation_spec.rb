
RSpec.describe SlackSmartBot, "add_vacation" do
  describe "add vacation" do
    describe "on external channel" do
      channel = :cexternal
      user = :uadmin

      before(:each) do
        send_message "delete vacation 1", from: user , to: channel
      end
      after(:all) do
        send_message "delete vacation 1", from: user , to: channel
      end

      it 'is possible to add single vacation' do
        send_message "add vacation 2022/08/01", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Period has been added/i)
      end

      it 'is possible to add single sick time' do
        send_message "add sick 2022/08/01", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Period has been added/i)
      end

      it 'is possible to add today time off' do
        send_message "add sick today", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Period has been added/i)
      end

      it 'is possible to add tomorrow time off' do
        send_message "add sick tomorrow", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Period has been added/i)
      end

      it 'is possible to add next week time off' do
        send_message "add sick next week", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Period has been added/i)
      end

      it 'is possible to add vacation period' do
        send_message "add vacation from 2022/08/01 to 2022/08/03", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Period has been added/i)
      end

      it 'is possible to add sick period' do
        send_message "add sick from 2022/08/01 to 2022/08/03", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Period has been added/i)
      end      

      it 'is not possible to add wrong date' do
        send_message "add sick from 2022/48/01 to 2022/08/03", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like the date is not in the correct format: YYYY\/MM\/DD or is a wrong date/i)
        send_message "add vacation from 2022/02/01 to 2022/02/31", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like the date is not in the correct format: YYYY\/MM\/DD or is a wrong date/i)
      end      

      it 'is not possible to add wrong format YYYY/MM/DD' do
        send_message "add sick from 2022/03/01 to 2022/31/03", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/is not in the correct format: YYYY\/MM\/DD or is a wrong date/i)
        send_message "add vacation from 2022/31/03 to 2022/04/05", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/is not in the correct format: YYYY\/MM\/DD or is a wrong date/i)
      end      

    end


  end
end
