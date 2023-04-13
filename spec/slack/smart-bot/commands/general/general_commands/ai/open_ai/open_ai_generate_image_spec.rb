RSpec.describe SlackSmartBot, "open_ai_generate_image" do
  describe "open_ai generate image" do
    describe "on direct message" do
      channel = DIRECT.user1.ubot
      user = :user1

      before(:all) do
        skip("no api key") unless ENV["OPENAI_ACCESS_TOKEN"].to_s != ""
        #delete all .png files on tmp folder
        Dir.glob("./spec/bot/tmp/*.png").each do |file|
          File.delete(file)
        end
      end
      it 'displays error when using repeat without previous image' do
        send_message "??i", from: user, to: channel
        send_message "?ir", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Sorry, I need to generate an image first. Use `\?i PROMPT` to generate an image/)
      end
      it 'restarts conversation when ??i PROMPT' do
        prompt = "cat black and white"
        send_message "??i #{prompt}", from: user, to: channel
        sleep 10
        buff = buffer(to: channel, from: :ubot).join
        session_id = buff.scan(/Session: _<#{prompt}...>_ \(id:(\d+)\)/).join
        expect(buffer(to: channel, from: :ubot).join).to match(/tmp\/smartbotuser1_#{session_id}\.png/)
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session: _<#{prompt}...>_ \(id:#{session_id}/)
        send_message "?i eating a banana", from: user, to: channel
        sleep 10
        expect(buffer(to: channel, from: :ubot).join).to match(/tmp\/smartbotuser1_#{session_id}\.png/)
        expect(buffer(to: channel, from: :ubot).join).to match(/eating a banana/)
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session: _<#{prompt}...>_ \(id:#{session_id}/)
        prompt = "blonde woman jumping"
        send_message "??i #{prompt}", from: user, to: channel
        sleep 10
        buff = buffer(to: channel, from: :ubot).join
        new_session_id = buff.scan(/Session: _<#{prompt}...>_ \(id:(\d+)\)/).join
        expect(session_id).not_to eq(new_session_id)
        expect(buffer(to: channel, from: :ubot).join).to match(/Session: _<#{prompt}...>_ \(id:#{new_session_id}/)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/tmp\/smartbotuser1_#{session_id}\.png/)
        expect(buffer(to: channel, from: :ubot).join).to match(/tmp\/smartbotuser1_#{new_session_id}\.png/)
      end

      it 'generates a new image when using repeat' do
        send_message "??i cat black and white", from: user, to: channel
        sleep 10
        buff = buffer(to: channel, from: :ubot).join
        session_id = buff.scan(/Session: _<cat black and white...>_ \(id:(\d+)\)/).join
        expect(bufferc(to: channel, from: :ubot).join).to match(/tmp\/smartbotuser1_#{session_id}\.png/)
        send_message "?ir", from: user, to: channel
        sleep 10
        buff = buffer(to: channel, from: :ubot).join
        expect(buff).to match(/tmp\/smartbotuser1_#{session_id}\.png/)
        expect(buff).to match(/Session: _<cat black and white...>_ \(id:#{session_id}/)
        expect(buff).to match(/Repeat/)
      end

    end
  end
end
