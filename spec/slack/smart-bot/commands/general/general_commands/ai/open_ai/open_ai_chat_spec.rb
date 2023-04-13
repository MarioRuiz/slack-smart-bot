RSpec.describe SlackSmartBot, "open_ai_chat" do
  describe "open_ai chat gpt" do
    describe "on direct message" do
      channel = DIRECT.user1.ubot
      user = :user1

      before(:all) do
        skip("no api key") unless ENV["OPENAI_ACCESS_TOKEN"].to_s != ""
      end

      it "restarts conversation when ??" do
        send_message "??", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Let's start a new conversation. Ask me anything./)
      end

      it 'restarts conversation when ?? PROMPT' do
        prompt = "how much is 3 plus 3"
        send_message "?? #{prompt}", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session: _<#{prompt}...>_ \(id:/)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(6|six)/)
        send_message "? and plus two", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session: _<#{prompt}...>_ \(id:/)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(8|eight)/)
        prompt = "and plus three"
        send_message "?? #{prompt}", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session: _<#{prompt}...>_ \(id:/)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/11/)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/eleven/)
      end

      it 'uses personsal api token' do
        send_message "set personal settings ai.open_ai.access_token wrong", from: user, to: channel
        send_message "?? hola", from: user, to: channel
        sleep 3
        send_message "delete personal settings ai.open_ai.access_token", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Incorrect API key provided/)
        prompt = "how much is 3 plus 3"
        send_message "?? #{prompt}", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session: _<#{prompt}...>_ \(id:/)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(6|six)/)
      end


    end
  end
end
