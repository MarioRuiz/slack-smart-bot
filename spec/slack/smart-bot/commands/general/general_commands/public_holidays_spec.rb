RSpec.describe SlackSmartBot, "public_holidays" do
  describe "public holidays" do
    describe "on external channel" do
      channel = :cexternal
      user = :uadmin
      before(:all) do
        skip("no api key") unless ENV["CALENDARIFIC_API_KEY"].to_s != ""
      end

      it "displays Country not found" do
        send_message "public holidays WRONG", from: user, to: channel
        sleep 2
        expect(buffer(to: channel, from: :ubot).join).to match(/Country WRONG not found/i)
      end

      it "displays the state in the country is not found" do
        send_message "public holidays United States/WRONG", from: user, to: channel
        sleep 2
        expect(buffer(to: channel, from: :ubot).join).to match(/No holidays found in United States Wrong/im)
        expect(buffer(to: channel, from: :ubot).join).to match(/Be sure the Country and State are written correctly\. Try using just the Country, not all countries are supporting States/im)
        expect(buffer(to: channel, from: :ubot).join).to match(/All States found in #{Date.today.year} United States/im)
        expect(buffer(to: channel, from: :ubot).join).to match(/Alabama/im)
        expect(buffer(to: channel, from: :ubot).join).to match(/Florida/im)
      end

      it "displays the holidays for a country without states" do
        send_message "public holidays Iceland", from: user, to: channel
        sleep 4
        expect(buffer(to: channel, from: :ubot).join).to match(/Holidays in Iceland in #{Date.today.year}/im)
      end

      it "displays the holidays for a country with states" do
        send_message "public holidays United States/California", from: user, to: channel
        sleep 4
        expect(buffer(to: channel, from: :ubot).join).to match(/Holidays in United States California in #{Date.today.year}/im)
        expect(buffer(to: channel, from: :ubot).join).to match(/Christmas Day/im)
      end

      it "displays the holidays for a country and a year/month" do
        send_message "public holidays United States/California 2023/12", from: user, to: channel
        sleep 4
        expect(buffer(to: channel, from: :ubot).join).to match(/Holidays in United States California in 2023-12/im)
        expect(buffer(to: channel, from: :ubot).join).to match(/Christmas Day/im)
      end
      it "displays the holidays for a country and a year/month/day" do
        send_message "public holidays United States/California 2023/12/25", from: user, to: channel
        sleep 4
        expect(buffer(to: channel, from: :ubot).join).to match(/Holidays in United States California in 2023-12-25/im)
        expect(buffer(to: channel, from: :ubot).join).to match(/Christmas Day/im)
      end
      it "displays error for Too many holidays to show" do
        send_message "public holidays United States", from: user, to: channel
        sleep 4
        expect(buffer(to: channel, from: :ubot).join).to match(/Too many holidays to show, please refine your search/im)
        expect(buffer(to: channel, from: :ubot).join).to match(/All States found in #{Date.today.year} United States/im)
        expect(buffer(to: channel, from: :ubot).join).to match(/Alabama/im)
        expect(buffer(to: channel, from: :ubot).join).to match(/Alaska/im)
        expect(buffer(to: channel, from: :ubot).join).to match(/Arizona/im)
        expect(buffer(to: channel, from: :ubot).join).to match(/Florida/im)
      end

      describe "calendar" do
        it "displays no country found" do
          send_message "calendar wrongcountry", from: user, to: channel
          sleep 4
          expect(buffer(to: channel, from: :ubot).join).to match(/Country wrongcountry not found/i)
          expect(buffer(to: channel, from: :ubot).join).to match(/Calendar #{Date.today.year} wrongcountry/i)
          expect(buffer(to: channel, from: :ubot).join).to match(/January/i)
          expect(buffer(to: channel, from: :ubot).join).to match(/December/i)
          description = ":large_yellow_square: weekend \/ :white_square: weekday \/ :white_small_square: not in month \/ :large_red_square: Public Holiday"
          expect(buffer(to: channel, from: :ubot).join).to match(/#{description}/i)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/Vacation/i)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/Sick/i)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/Your public holidays/i)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/you have spent/i)
        end

        it 'displays all states found' do
          send_message "calendar Spain", from: user, to: channel
          sleep 4
          expect(buffer(to: channel, from: :ubot).join).to match(/All States found in #{Date.today.year} Spain/i)
          expect(buffer(to: channel, from: :ubot).join).to match(/Madrid/i)
          expect(buffer(to: channel, from: :ubot).join).to match(/Calendar #{Date.today.year} Spain/i)
          expect(buffer(to: channel, from: :ubot).join).to match(/January/i)
          expect(buffer(to: channel, from: :ubot).join).to match(/December/i)
          description = ":large_yellow_square: weekend \/ :white_square: weekday \/ :white_small_square: not in month \/ :large_red_square: Public Holiday"
          expect(buffer(to: channel, from: :ubot).join).to match(/#{description}/i)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/Vacation/i)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/Sick/i)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/Your public holidays/i)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/you have spent/i)
        end

        it 'displays the country/state calendar for present year' do
          send_message "calendar Spain/Madrid", from: user, to: channel
          sleep 4
          expect(buffer(to: channel, from: :ubot).join).not_to match(/All States found in #{Date.today.year} Spain/i)
          expect(buffer(to: channel, from: :ubot).join).to match(/Calendar #{Date.today.year} Spain\/madrid/i)
          expect(buffer(to: channel, from: :ubot).join).to match(/January/i)
          expect(buffer(to: channel, from: :ubot).join).to match(/December/i)
          description = ":large_yellow_square: weekend \/ :white_square: weekday \/ :white_small_square: not in month \/ :large_red_square: Public Holiday"
          expect(buffer(to: channel, from: :ubot).join).to match(/#{description}/i)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/Vacation/i)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/Sick/i)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/Your public holidays/i)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/you have spent/i)
        end

        it 'displays the country/state calendar for specified year' do
          send_message "calendar Iceland 2022", from: user, to: channel
          sleep 4
          expect(buffer(to: channel, from: :ubot).join).not_to match(/All States found in 2022 iceland/i)
          expect(buffer(to: channel, from: :ubot).join).to match(/Calendar 2022 iceland/i)
          expect(buffer(to: channel, from: :ubot).join).to match(/January/i)
          expect(buffer(to: channel, from: :ubot).join).to match(/December/i)
          description = ":large_yellow_square: weekend \/ :white_square: weekday \/ :white_small_square: not in month \/ :large_red_square: Public Holiday"
          expect(buffer(to: channel, from: :ubot).join).to match(/#{description}/i)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/Vacation/i)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/Sick/i)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/Your public holidays/i)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/you have spent/i)
        end
        
      end

    end
  end
end
