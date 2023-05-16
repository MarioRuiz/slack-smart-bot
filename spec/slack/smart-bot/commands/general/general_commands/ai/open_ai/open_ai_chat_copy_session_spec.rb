RSpec.describe SlackSmartBot, "open_ai_chat_copy_session" do
  describe "open_ai chat gpt copy session" do
    describe "on channel bot" do
      channel = :cbot1cm
      user = :user1

      before(:all) do
        skip("no api key") unless ENV["OPENAI_ACCESS_TOKEN"].to_s != ""
      end

      it 'copies a session with no new name given' do
        send_message "chatgpt mySessioncopy1", from: user, to: channel
        sleep 3
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<mySessioncopy1>_ model:/i)
        prompt = "how much is 3 plus 3"
        send_message "? #{prompt}", from: user, to: channel
        sleep 3
        expect(bufferc(to: channel, from: :ubot).join).to match(/(6|six)/)
        send_message "chatgpt copy mySessioncopy1", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session mySessioncopy1 copied to mySessioncopy11/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/Now you can call `\^chatGPT mySessioncopy11` to use it/i)
        send_message "chatgpt mySessioncopy11", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySessioncopy11>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/I just loaded/i)
        send_message "? and plus 2", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySessioncopy11>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(8|eight)/)
        send_message "chatgpt mySessioncopy1", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySessioncopy1>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/I just loaded/i)
        send_message "? and plus 3", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySessioncopy1>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(9|nine)/)        
      end

      it 'copies a session with new name given' do
        send_message "chatgpt mySession_copy", from: user, to: channel
        sleep 3
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<mySession_copy>_ model:/i)
        prompt = "?how much is 3 plus 3"
        send_message prompt, from: user, to: channel
        sleep 3
        expect(bufferc(to: channel, from: :ubot).join).to match(/(6|six)/)
        send_message "chatgpt copy mySession_copy mySession_new_copy", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session mySession_copy copied to mySession_new_copy/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/Now you can call `\^chatGPT mySession_new_copy` to use it/i)
        send_message "chatgpt mySession_new_copy", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession_new_copy>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/I just loaded/i)
        send_message "? and plus 2", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession_new_copy>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(8|eight)/)
        send_message "chatgpt mySession_copy", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession_copy>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/I just loaded/i)
        send_message "? and plus 3", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession_copy>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(9|nine)/)
      end

      it "is returning not found if session doesn't exist" do
        send_message "chatgpt copy wrongSession", from: user, to: channel
        sleep 1
        expect(bufferc(to: channel, from: :ubot).join).to match(/You don't have a session with that name/i)
      end

    end
  end
end
