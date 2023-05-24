RSpec.describe SlackSmartBot, "open_ai_chat_delete_session" do
  describe "open_ai chat gpt delete session" do
    describe "on channel bot" do
      channel = :cbot1cm
      user = :user1
      seconds_to_wait = ENV['OPEN_AI_SECONDS_TO_WAIT'].to_i || 3

      before(:all) do
        skip("no api key") unless ENV["OPENAI_ACCESS_TOKEN"].to_s != ""
      end

      it 'is deleting a session' do
        send_message "chatgpt mySession9", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<mySession9>_ model:/i)
        send_message "chatgpt delete mySession9", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session \*mySession9\* deleted/i)
        send_message "chatgpt mySession9", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession9>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/I just loaded/i)
        send_message "??d mySession9", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session \*mySession9\* deleted/i)
      end

      it "is returning not found if session doesn't exist" do
        send_message "chatgpt delete wrongSession", from: user, to: channel
        sleep 1
        expect(bufferc(to: channel, from: :ubot).join).to match(/You don't have a session with that name/i)
      end

    end
  end
end
