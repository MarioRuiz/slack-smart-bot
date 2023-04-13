RSpec.describe SlackSmartBot, "open_ai_generate_image" do
  describe "open_ai generate image" do
    describe "on direct message" do
      channel = DIRECT.user1.ubot
      user = :user1
      #todo: add tests when uploading pictures
      before(:all) do
        skip("no api key") unless ENV["OPENAI_ACCESS_TOKEN"].to_s != ""
        #delete all .png files on tmp folder
        Dir.glob("./spec/bot/tmp/*.png").each do |file|
          File.delete(file)
        end
      end
      it 'displays error when using variation without previous image' do
        send_message "??i", from: user, to: channel
        send_message "?iv", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Sorry, I need to generate an image first. Use `\?i PROMPT` to generate an image/)
      end

      it 'generates a new image when using variation' do
        prompt = "man riding a horse"
        send_message "??i #{prompt}", from: user, to: channel
        sleep 10
        buff = buffer(to: channel, from: :ubot).join
        session_id = buff.scan(/Session: _<#{prompt}...>_ \(id:(\d+)\)/).join
        expect(buff).to match(/tmp\/smartbotuser1_\d+\.png/)
        clean_buffer()
        send_message "?iv", from: user, to: channel
        sleep 10
        expect(buffer(to: channel, from: :ubot).join).to match(/tmp\/smartbotuser1_#{session_id}\.png/)
        expect(buffer(to: channel, from: :ubot).join).to match(/Variation/)
        expect(buffer(to: channel, from: :ubot).join).to match(/#{prompt}/)
      end

      it 'generates variations depending on number of variations supplied' do
        prompt = "man riding a horse"
        send_message "??i #{prompt}", from: user, to: channel
        sleep 10
        buff = buffer(to: channel, from: :ubot).join
        session_id = buff.scan(/Session: _<#{prompt}...>_ \(id:(\d+)\)/).join
        expect(buff).to match(/tmp\/smartbotuser1_\d+\.png/)
        clean_buffer()
        send_message "?iv2", from: user, to: channel
        sleep 20
        expect(buffer(to: channel, from: :ubot).join).to match(/tmp\/smartbotuser1_#{session_id}\.png/)
        expect(buffer(to: channel, from: :ubot).join).to match(/Variation 1 of 2/)
        expect(buffer(to: channel, from: :ubot).join).to match(/Variation 2 of 2/)
        expect(buffer(to: channel, from: :ubot).join).to match(/#{prompt}/)
      end
      it 'cannot generate more than 9 variations at a time' do
        send_message "??i man riding a horse over a bridge", from: user, to: channel
        sleep 10
        send_message "?iv10", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/I can only generate up to 9 variations at a time. Please try again/)
      end
    end
  end
end
