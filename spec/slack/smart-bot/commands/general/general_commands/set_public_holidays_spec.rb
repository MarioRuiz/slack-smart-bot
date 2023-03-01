RSpec.describe SlackSmartBot, "set public holidays" do
    describe "set public holidays" do
        describe "on external channel" do
            channel = :cexternal
            user = :uadmin
            it 'displays error when wrong country' do
                send_message "set public holidays to WRONG", from: user , to: channel
                expect(buffer(to: channel, from: :ubot).join).to match(/Be sure the country and state are correct/i)
            end
            it 'displays error when wrong state' do
                send_message "set public holidays to United States/WRONG", from: user , to: channel
                expect(buffer(to: channel, from: :ubot).join).to match(/Be sure the country and state are correct/i)
            end
            it 'displays correct public holidays when set' do
                send_message "set public holidays to Spain/Madrid", from: user , to: channel
                expect(buffer(to: channel, from: :ubot).join).to match(/Public holidays for \*Spain\/Madrid\* set/i)
                send_message "add sick today", from: user, to: DIRECT.uadmin.ubot
                send_message "see my vacations", from: user, to: DIRECT.uadmin.ubot
                expect(buffer(to: DIRECT.uadmin.ubot, from: :ubot).join).to match(/Your public holidays are set for spain\/madrid/i)
            end
        end
    end
end
