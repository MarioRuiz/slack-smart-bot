RSpec.describe SlackSmartBot, "open_ai_chat" do
  describe "open_ai chat gpt" do
    describe "on direct message" do
      channel = DIRECT.user1.ubot
      user = :user1
      seconds_to_wait = ENV['OPEN_AI_SECONDS_TO_WAIT'].to_i || 3

      before(:all) do
        skip("no api key") unless ENV["OPENAI_ACCESS_TOKEN"].to_s != ""
      end

      it 'uses personsal api token' do
        send_message "set personal settings ai.open_ai.access_token wrong", from: user, to: channel
        send_message "?? hola", from: user, to: channel
        sleep seconds_to_wait
        send_message "delete personal settings ai.open_ai.access_token", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/(Incorrect API key provided|invalid_api_key)/i)
        prompt = "how much is 3 plus 3"
        send_message "?? #{prompt}", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/Session: _<#{prompt}...>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(6|six)/)
      end


    end
    describe "on channel bot" do
      channel = :cbot1cm
      user = :user1
      seconds_to_wait = ENV['OPEN_AI_SECONDS_TO_WAIT'].to_i || 3

      before(:all) do
        skip("no api key") unless ENV["OPENAI_ACCESS_TOKEN"].to_s != ""
      end

      it "restarts temporary session when ??" do
        send_message "??", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/Let's start a new temporary conversation. Ask me anything./)
      end

      it 'restarts temporary session when ?? PROMPT' do
        prompt = "how much is 3 plus 3"
        send_message "?? #{prompt}", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/Temporary session: _<#{prompt}...>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(6|six)/)
        send_message "? and plus two", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/Temporary Session: _<#{prompt}...>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(8|eight)/)
        prompt = "2 plus 2"
        send_message "?? #{prompt}", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/Temporary Session: _<#{prompt}...>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(4|four)/)
      end

      it 'is listening when starting the temporary session to be responded on a thread' do
        prompt = "how much is 3 plus 3"
        thread = "opeanai#{'3:L&'.gen}"
        send_message "^?? #{prompt}", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Temporary session: _<#{prompt}...>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(6|six)/)
        send_message "and plus two", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Temporary Session: _<#{prompt}...>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(8|eight)/)
      end

      it 'is creating the session name indicated' do
        prompt = "how much is 3 plus 3"
        send_message "chatgpt mySession1", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<mySession1>_ model:/i)
        send_message "?#{prompt}", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession1>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(6|six)/)
        
        send_message "chatgpt start mySession2", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<mySession2>_ model:/i)
        send_message "?#{prompt}", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession2>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(6|six)/)

        send_message "??s mySession3", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<mySession3>_ model:/i)
        send_message "?#{prompt}", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession3>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(6|six)/)

      end

      it 'is creating the session name indicated on thread' do
        prompt = "how much is 3 plus 4"
        thread = "openai#{'3:L&'.gen}"
        send_message "^chatgpt mySession4", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession4>_ model:/i)
        send_message "#{prompt}", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession4>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(7|seven)/)
      end

      it 'is selecting the model indicated' do
        thread = "openai#{'3:L&'.gen}"
        send_message "^chatgpt mySession5 wrong_model", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession5>_ model: wrong_model/i)
        send_message "how much is 3 plus 4", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        message = 'The model `wrong_model` does not exist'
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/#{message}/i)
      end

      it 'is continuing the session indicated' do
        thread = "openai#{'3:L&'.gen}"
        send_message "^chatgpt mySession6", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession6>_ model:/i)
        send_message "how much is 3 plus 4", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession6>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(7|seven)/)
        send_message "chatgpt mySession6", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession6>_ model:/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/There\s+are\s+\*\d+\s+prompts\*\s+in\s+this\s+session/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/This was the \*last prompt\* from the session:/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/\*Me>\* how much is 3 plus 4/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/I just loaded \*mySession6\*/)
        send_message "?and multiply by 2", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession6>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/(14|fourteen)/)
        send_message "chatgpt continue mySession6", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession6>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/I just loaded \*mySession6\*/)
        send_message "??c mySession6", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/Session _<mySession6>_ model:/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/I just loaded \*mySession6\*/)
      end

      it 'is skipping line when using hyphen' do
        thread = "openai#{'3:L&'.gen}"
        send_message "^chatgpt mySession8", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession8>_ model:/i)
        send_message "how much is 3 plus 6", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySession8>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(9|nine)/)
        send_message "-and minus 2", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to eq ""
      end

      it 'is tagging the session indicated' do
        send_message "chatgpt mySessionTag >myTag", from: user, to: channel
        sleep seconds_to_wait
        send_message "chatgpt sessions", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/tag:\s+>\*mytag\*/)
      end

      it 'is adding the description indicated' do
        send_message 'chatgpt mySessionDesc "myDesc"', from: user, to: channel
        sleep seconds_to_wait
        send_message "chatgpt sessions", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/\*`mySessionDesc`\*: _"myDesc"_/)
      end

      it 'is downloading the url specified and add it to the prompt' do
        send_message "?? is it displayed on this webpage !https://github.com/MarioRuiz/nice_http/blob/master/lib/nice_http/defaults.rb the sentence 'Wrong sentence'", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/No/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/content extracted and added to prompt/i)
        send_message "? is it displayed '@async_resource'", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/yes/i)
      end

      it 'restarts the conversation when sent `??` on a given session name' do
        thread = "openai#{'3:L&'.gen}"
        send_message "^chatgpt mySessionRestart", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySessionRestart>_ model:/i)
        send_message "how much is 3 plus 6", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySessionRestart>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(9|nine)/)
        send_message "??", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySessionRestart>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/All prompts were removed from session/)
        send_message "and plus 2", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Session _<mySessionRestart>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).not_to match(/(11|eleven)/)
      end

      it 'restarts the conversation when sent `??` on a temporary session' do
        thread = "openai#{'3:L&'.gen}"
        send_message "^??", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/Let's start a new temporary conversation. Ask me anything/i)
        send_message "how much is 3 plus 6", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Temporary session: _<how much is 3 plus 6...>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/(9|nine)/)
        send_message "??", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/Let's start a new temporary conversation. Ask me anything/i)
        send_message "and plus 2", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/Temporary session: _<and plus 2...>_ model:/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).not_to match(/(11|eleven)/)
      end

      it 'calls a smartbot command and the outuput is added to the prompt in a temporary session' do
        send_message "bot rules ?? how to use echo command", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).not_to match(/Specific commands/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/echo/i)
      end

      it 'calls a smartbot command and the outuput is added to the prompt in a given session on a thread' do
        thread = "openai#{'3:L&'.gen}"
        send_message "^chatgpt mySessionHelp", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/mySessionHelp/i)
        send_message "bot rules ?? how to use echo command", from: user, to: channel, thread_ts: thread
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).to match(/mySessionHelp/i)
        expect(buffer(to: channel, from: :ubot, thread_ts: thread).join).not_to match(/Specific commands/i)
        expect(bufferc(to: channel, from: :ubot, thread_ts: thread).join).to match(/echo/i)
      end

      #todo: enable this test when the access token we use is able to use 32k model
      xit "uses the generic model for smartbot when using the command as an input for chatgpt and doesn't affect model for temporary session" do
        send_message "bot rules ?? how to use echo command", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/32k/i)
        send_message "?? hola", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).not_to match(/32k/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/gpt-3\.5/i)
        send_message "? que tal", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).not_to match(/32k/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/gpt-3\.5/i)
        send_message "bot rules ?? how to use echo command", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/32k/i)
        send_message "? more examples", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/32k/i)        
      end

    end
  end
end
