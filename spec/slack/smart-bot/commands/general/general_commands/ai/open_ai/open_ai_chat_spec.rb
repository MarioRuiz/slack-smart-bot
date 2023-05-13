RSpec.describe SlackSmartBot, "open_ai_chat" do
  describe "open_ai chat gpt" do
    describe "on direct message" do
      channel = DIRECT.user1.ubot
      user = :user1

      before(:all) do
        skip("no api key") unless ENV["OPENAI_ACCESS_TOKEN"].to_s != ""
      end

      it 'uses personsal api token' do
        send_message "set personal settings ai.open_ai.access_token wrong", from: user, to: channel
        send_message "?? hola", from: user, to: channel
        sleep 3
        send_message "delete personal settings ai.open_ai.access_token", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/(Incorrect API key provided|invalid_api_key)/i)
        prompt = "how much is 3 plus 3"
        send_message "?? #{prompt}", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session: _<#{prompt}...>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(6|six)/)
      end


    end
    describe "on channel bot" do
      channel = :cbot1cm
      user = :user1

      before(:all) do
        skip("no api key") unless ENV["OPENAI_ACCESS_TOKEN"].to_s != ""
      end

      before(:each) do
        
      end

      it "restarts temporary session when ??" do
        send_message "??", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Let's start a new temporary conversation. Ask me anything./)
      end

      it 'restarts temporary session when ?? PROMPT' do
        prompt = "how much is 3 plus 3"
        send_message "?? #{prompt}", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Temporary session: _<#{prompt}...>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(6|six)/)
        send_message "? and plus two", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Temporary Session: _<#{prompt}...>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(8|eight)/)
        prompt = "2 plus 2"
        send_message "?? #{prompt}", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Temporary Session: _<#{prompt}...>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(4|four)/)
      end

      it 'is listening when starting the temporary session to be responded on a thread' do
        prompt = "how much is 3 plus 3"
        thread = "opeanai#{'3:L&'.gen}"
        send_message "^?? #{prompt}", from: user, to: channel, thread_ts: thread
        sleep 3
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Temporary session: _<#{prompt}...>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(6|six)/)
        send_message "and plus two", from: user, to: channel, thread_ts: thread
        sleep 3
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Temporary Session: _<#{prompt}...>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(8|eight)/)
      end

      it 'is not possible to add collaborators to temporary sessions' do
        prompt = "how much is 3 plus 3"
        thread = "opeanai#{'3:L&'.gen}"
        send_message "^?? #{prompt}", from: user, to: channel, thread_ts: thread
        sleep 3
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Temporary session: _<#{prompt}...>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(6|six)/)
        send_message "add collaborator <@#{USER2}>", from: user, to: channel, thread_ts: thread
        sleep 3
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/You can add collaborators for the chatGPT session only when started on a thread and using a session name/i)
      end

      it 'is creating the session name indicated' do
        prompt = "how much is 3 plus 3"
        send_message "chatgpt mySession1", from: user, to: channel
        sleep 3
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<mySession1>_ model:/i)
        send_message "?#{prompt}", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession1>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(6|six)/)
        
        send_message "chatgpt start mySession2", from: user, to: channel
        sleep 3
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<mySession2>_ model:/i)
        send_message "?#{prompt}", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession2>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(6|six)/)

        send_message "??s mySession3", from: user, to: channel
        sleep 3
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<mySession3>_ model:/i)
        send_message "?#{prompt}", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession3>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(6|six)/)

      end

      it 'is creating the session name indicated on thread' do
        prompt = "how much is 3 plus 4"
        thread = "openai#{'3:L&'.gen}"
        send_message "^chatgpt mySession4", from: user, to: channel, thread_ts: thread
        sleep 3
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession4>_ model:/i)
        send_message "#{prompt}", from: user, to: channel, thread_ts: thread
        sleep 3
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession4>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(7|seven)/)
      end

      it 'is selecting the model indicated' do
        thread = "openai#{'3:L&'.gen}"
        send_message "^chatgpt mySession5 wrong_model", from: user, to: channel, thread_ts: thread
        sleep 3
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession5>_ model: wrong_model/i)
        send_message "how much is 3 plus 4", from: user, to: channel, thread_ts: thread
        sleep 3
        message = 'The model `wrong_model` does not exist'
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/#{message}/i)
      end

      it 'is continuing the session indicated' do
        thread = "openai#{'3:L&'.gen}"
        send_message "^chatgpt mySession6", from: user, to: channel, thread_ts: thread
        sleep 3
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession6>_ model:/i)
        send_message "how much is 3 plus 4", from: user, to: channel, thread_ts: thread
        sleep 3
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession6>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(7|seven)/)
        send_message "chatgpt mySession6", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession6>_ model:/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/You already have a session with that name/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/I just loaded \*mySession6\*/)
        send_message "?and multiply by 2", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession6>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(14|fourteen)/)
        send_message "chatgpt continue mySession6", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession6>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/I just loaded \*mySession6\*/)
        send_message "??c mySession6", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession6>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/I just loaded \*mySession6\*/)
      end

      it 'is adding a collaborator' do
        thread = "openai#{'3:L&'.gen}"
        send_message "^chatgpt mySession7", from: user, to: channel, thread_ts: thread
        sleep 3
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession7>_ model:/i)
        send_message "how much is 3 plus 5", from: user, to: channel, thread_ts: thread
        sleep 3
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession7>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(8|eight)/)
        send_message "hola", from: :user2, to: channel, thread_ts: thread
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to eq ""
        send_message "add collaborator <@#{USER2}>", from: user, to: channel, thread_ts: thread
        sleep 3
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/Now <@smartbotuser2> is a collaborator of this session only when on a thread/i)
        send_message "and plus 2", from: :user2, to: channel, thread_ts: thread
        sleep 3
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession7>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(10|ten)/)
      end

      it 'is skipping line when using hyphen' do
        thread = "openai#{'3:L&'.gen}"
        send_message "^chatgpt mySession8", from: user, to: channel, thread_ts: thread
        sleep 3
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession8>_ model:/i)
        send_message "how much is 3 plus 6", from: user, to: channel, thread_ts: thread
        sleep 3
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession8>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(9|nine)/)
        send_message "-and minus 2", from: user, to: channel, thread_ts: thread
        sleep 3
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to eq ""
      end

      it 'is deleting a session' do
        send_message "chatgpt delete wrongSession", from: user, to: channel
        sleep 1
        expect(bufferc(to: channel, from: :ubot).join).to match(/You don't have a session with that name/i)
        send_message "chatgpt mySession9", from: user, to: channel
        sleep 3
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<mySession9>_ model:/i)
        send_message "chatgpt delete mySession9", from: user, to: channel
        sleep 3
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session \*mySession9\* deleted/i)
        send_message "chatgpt mySession9", from: user, to: channel
        sleep 3
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession9>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).not_to match(/I just loaded/i)
        send_message "??d mySession9", from: user, to: channel
        sleep 3
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session \*mySession9\* deleted/i)
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
        send_message "chatgpt get wrong_name", from: user, to: channel
        sleep 1
        expect(bufferc(to: channel, from: :ubot).join).to match(/You don't have a session with that name/i)
      end

      it 'is listing the session names' do
        send_message "chatgpt mySession11", from: user, to: channel
        sleep 3
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<mySession11>_ model:/i)
        send_message "chatgpt mySession12", from: user, to: channel
        sleep 3
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<mySession12>_ model:/i)
        send_message "chatgpt mySession13", from: user, to: channel
        sleep 3
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

    end
  end
end
