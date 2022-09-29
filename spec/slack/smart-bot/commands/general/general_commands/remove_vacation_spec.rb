
RSpec.describe SlackSmartBot, "remove_vacation" do
  describe "remove vacation" do
    describe "on external channel" do
      channel = :cexternal
      user = :uadmin

      before(:each) do
        send_message "delete vacation 1", from: user , to: channel
        send_message "add vacation 2022/08/01", from: user , to: channel
      end
      after(:all) do
        send_message "delete vacation 1", from: user , to: channel
      end

      it 'is not possible to delete a wrong id' do
        send_message "delete vacation 999", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like the ID supplied doesn't exist/i)
      end

      it 'is possible to remove vacations' do
        send_message "remove vacation 1", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Your time off has been removed/i)
      end

      it 'is possible to delete vacations' do
        send_message "delete vacation 1", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Your time off has been removed/i)
      end

      it 'is possible to delete sick time' do
        send_message "remove sick 1", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Your time off has been removed/i)
      end

      it 'is possible to delete time off' do
        send_message "delete time off 1", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Your time off has been removed/i)
      end

      it 'is displaying not time off added' do
        send_message "delete vacation 1", from: :user1, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like you don't have any time off added/i)
      end


    end


  end
end
