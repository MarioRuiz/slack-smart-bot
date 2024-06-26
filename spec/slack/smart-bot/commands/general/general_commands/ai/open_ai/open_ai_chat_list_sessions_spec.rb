RSpec.describe SlackSmartBot, "open_ai_chat_list_sessions" do
  describe "open_ai chat gpt list sessions" do
    describe "on channel bot" do
      channel = :cbot1cm
      user = :user1
      seconds_to_wait = ENV['OPEN_AI_SECONDS_TO_WAIT'].to_i || 3

      before(:all) do
        skip("no api key") unless ENV["OPENAI_ACCESS_TOKEN"].to_s != ""
      end

      it 'is listing the session names' do
        send_message "chatgpt mySession11", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<mySession11>_ model:/i)
        send_message "chatgpt mySession12", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<mySession12>_ model:/i)
        send_message "chatgpt mySession13", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<mySession13>_ model:/i)
        send_message "chatgpt list sessions", from: user, to: channel
        sleep 1
        expect(buffer(to: channel, from: :ubot).join).to match(/`mySession11`/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/`mySession12`/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/`mySession13`/i)
        send_message "??l", from: user, to: channel
        sleep 1
        expect(buffer(to: channel, from: :ubot).join).to match(/`mySession11`/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/`mySession12`/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/`mySession13`/i)
      end
      it 'is listing the session names by tags' do
        send_message "chatgpt mySessionTag0 >myTag0", from: user, to: channel
        sleep seconds_to_wait
        send_message "chatgpt sessions >myTag0", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/Your >\*mytag0\* sessions/)
        expect(buffer(to: channel, from: :ubot).join).to match(/`mySessionTag0`/)
      end
      it 'is not listing tags when tag is not found' do
        send_message "chatgpt sessions >wrong_tag", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/You don't have any >\*wrong_tag\* sessions./)
      end

    end
  end
end
