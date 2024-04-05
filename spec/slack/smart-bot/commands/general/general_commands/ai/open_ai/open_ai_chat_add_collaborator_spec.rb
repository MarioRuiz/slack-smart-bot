RSpec.describe SlackSmartBot, "open_ai_chat_add_collaborator" do
  describe "open_ai chat gpt add collaborator" do
    describe "on channel bot" do
      channel = :cbot1cm
      user = :user1
      seconds_to_wait = ENV['OPEN_AI_SECONDS_TO_WAIT'].to_i || 3

      before(:all) do
        skip("no api key") unless ENV["OPENAI_ACCESS_TOKEN"].to_s != ""
      end

      it 'is not possible to add collaborators to temporary sessions' do
        prompt = "how much is 3 plus 3"
        thread = "opeanai#{'3:L&'.gen}"
        send_message "^?? #{prompt}", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Temporary session: _<#{prompt}...>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(6|six)/)
        send_message "add collaborator <@#{USER2}>", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/You can add collaborators for the chatGPT session only when started on a thread and using a session name/i)
      end

      it 'is adding a collaborator' do
        thread = "openai#{'3:L&'.gen}"
        send_message "^chatgpt mySession7", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession7>_ model:/i)
        send_message "how much is 3 plus 5", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession7>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(8|eight)/)
        send_message "hola", from: :user2, to: channel, thread_ts: thread
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to eq ""
        send_message "add collaborator <@#{USER2}>", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/Now <@smartbotuser2> is a collaborator of this session only when on a thread/i)
        send_message "and plus 2", from: :user2, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession7>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(10|ten)/)
      end

    end
  end
end
