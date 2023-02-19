
RSpec.describe SlackSmartBot, "see_vacations_team" do
  describe "see vacations team" do
    describe "on external channel and no teams" do
      channel = :cexternal
      user = :uadmin
      
      it 'displays there are no teams' do
        send_message "see vacations team example", from: user , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/There are no teams added yet/i)
        send_message "vacations team example", from: user , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/There are no teams added yet/i)
        send_message "time off team example", from: user , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/There are no teams added yet/i)
        send_message "vacations team example 2022/01/01", from: user , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/There are no teams added yet/i)
      end
    end 
    describe "on external channel" do
      channel = :cexternal
      user = :uadmin
      today = Date.today.strftime("%Y/%m/%d")

      before(:all) do
        send_message "add team example dev <@#{USER1}> <@#{USER2}> members <##{CEXTERNAL}|external_channel> contact_us <##{CEXTERNAL}|external_channel> : beautiful info", from: user , to: channel
        sleep 3
        send_message "add sick 2031/09/01", from: user , to: channel
        send_message "add vacation #{today}", from: user , to: channel
        send_message "add vacation from 2032/10/01 to 2032/12/01", from: user , to: channel
        send_message "add sick from 2022/01/01 to 2022/01/10", from: user , to: channel
      end
      after(:all) do
        send_message "delete vacation 1", from: user , to: channel
        send_message "delete vacation 2", from: user , to: channel
        send_message "delete vacation 3", from: user , to: channel
        send_message "delete vacation 4", from: user , to: channel
        send_message "delete team example", from: user , to: channel
        send_message "yes", from: user , to: channel
      end

      it "displays the team doesn't exixt" do
        send_message "vacations team wrong_team", from: user , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/It seems like the team \*wrong_team\* doesn't exist/i)
      end

      it 'displays the time off for team when calling the team' do
        send_message "team example", from: user , to: channel
        sleep 2
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Time Off example team\* from #{today}/i)
        if Date.today.wday == 0 or Date.today.wday == 6
          expect(buffer(to: channel, from: :ubot).join).to match(/#{today[-2..-1]} :large_orange_square:/i)
        else
          expect(buffer(to: channel, from: :ubot).join).to match(/#{today[-2..-1]} :large_red_square:/i)
        end
      end

      it 'displays the time off for team when calling vacations team NAME' do
        send_message "vacations team example", from: user , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Time Off example team\* from #{today}/i)
        if Date.today.wday == 0 or Date.today.wday == 6
          expect(buffer(to: channel, from: :ubot).join).to match(/#{today[-2..-1]} :large_orange_square:/i)
        else
          expect(buffer(to: channel, from: :ubot).join).to match(/#{today[-2..-1]} :large_red_square:/i)
        end
      end

      it 'displays the time off for team when calling vacations team NAME DATE' do
        send_message "vacations team example 2032/09/30", from: user , to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Time Off example team\* from 2032\/09\/30/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/30 :white_square: :large_red_square: :large_orange_square: :large_orange_square: 04 :large_red_square:/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/18 :large_red_square: :large_red_square: :large_red_square:/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/30 :white_square: :white_square: :large_yellow_square: :large_yellow_square: 04 :white_square: :white_square:/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/:large_yellow_square: :large_yellow_square: 18 :white_square: :white_square: :white_square:/i)        
      end


    end


  end
end
