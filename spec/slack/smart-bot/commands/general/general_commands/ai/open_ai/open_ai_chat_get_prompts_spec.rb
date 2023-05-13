RSpec.describe SlackSmartBot, "open_ai_chat_get_prompts" do
  describe "open_ai chat gpt get prompts" do
    describe "on channel bot" do
      channel = :cbot1cm
      user = :user1

      before(:all) do
        skip("no api key") unless ENV["OPENAI_ACCESS_TOKEN"].to_s != ""
      end

      it 'returns the prompts from session when calling get' do
        send_message "chatgpt mySession10", from: user, to: channel
        sleep 3
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<mySession10>_ model:/i)
        send_message "?how much is 3 plus 7", from: user, to: channel
        sleep 3
        expect(bufferc(to: channel, from: :ubot).join).to match(/(10|ten)/)
        send_message "?and plus 2", from: user, to: channel
        sleep 3
        expect(bufferc(to: channel, from: :ubot).join).to match(/(12|twelve)/)
        send_message "chatgpt get mySession10", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Me> how much is 3 plus 7/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/chatGPT> .*(10|ten).*/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/Me> and plus 2/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/chatGPT> .*(12|twelve).*/i)
        send_message "??g mySession10", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Me> how much is 3 plus 7/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/chatGPT> .*(10|ten).*/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/Me> and plus 2/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/chatGPT> .*(12|twelve).*/i)
      end

      it "returns not found if session doesn't exist" do
        send_message "chatgpt get wrong_name", from: user, to: channel
        sleep 1
        expect(bufferc(to: channel, from: :ubot).join).to match(/You don't have a session with that name/i)
      end

    end
  end
end
