RSpec.describe SlackSmartBot, "open_ai_chat_share_session" do
  describe "open_ai chat gpt share session" do
    describe "on channel bot" do
      channel = :cbot1cm
      user = :user1
      seconds_to_wait = ENV['OPEN_AI_SECONDS_TO_WAIT'].to_i || 3

      before(:all) do
        skip("no api key") unless ENV["OPENAI_ACCESS_TOKEN"].to_s != ""
        send_message "chatgpt mySessionshare", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<mySessionshare>_ model:/i)
        send_message "?how much is 3 + 7", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/10/)
      end
      before(:each) do
        send_message "chatgpt stop sharing mySessionshare", from: user, to: channel
        send_message "chatgpt stop sharing mySessionshare <##{CBOT1CM}|>", from: user, to: channel
        send_message "chatgpt delete mySessionshare", from: :user2, to: :cbot2cu
        sleep seconds_to_wait
      end
      it 'is displaying error message if session does not exist' do
        send_message "chatgpt share wrong_session", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/You don't have a session with that name/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/Call `chatGPT (list\s)?sessions` to see your saved sessions\./i)
      end

      it 'is sharing a session as public' do
        send_message "chatgpt share mySessionshare", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session \*mySessionshare\* is now public/i)
        send_message "chatgpt public sessions", from: :user2, to: :cbot2cu
        sleep seconds_to_wait
        expect(buffer(to: :cbot2cu, from: :ubot).join).to match(/Public sessions/)
        expect(buffer(to: :cbot2cu, from: :ubot).join).to match(/`mySessionshare`/)
        expect(bufferc(to: :cbot2cu, from: :ubot).join).to match(/shared by: \*smartbotuser1\*/)
        send_message "chatgpt use smartbotuser1 mySessionshare", from: :user2, to: :cbot2cu
        sleep seconds_to_wait
        expect(buffer(to: :cbot2cu, from: :ubot).join).to match(/Session mySessionshare \(smartbotuser1\) copied to mySessionshare/i)
        expect(bufferc(to: :cbot2cu, from: :ubot).join).to match(/Now you can call `\^chatGPT mySessionshare`/i)
        send_message "chatgpt mySessionshare", from: :user2, to: :cbot2cu
        sleep seconds_to_wait
        expect(bufferc(to: :cbot2cu, from: :ubot).join).to match(/10/)
        send_message "?and plus 2", from: :user2, to: :cbot2cu
        sleep seconds_to_wait
        expect(bufferc(to: :cbot2cu, from: :ubot).join).to match(/12/)
      end

      it 'is deleting a session as public' do
        send_message "chatgpt share mySessionshare", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session \*mySessionshare\* is now public/i)
        send_message "chatgpt stop sharing mySessionshare", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session \*mySessionshare\* is no longer public/i)
        send_message "chatgpt public sessions", from: :user2, to: :cbot2cu
        sleep seconds_to_wait
        expect(buffer(to: :cbot2cu, from: :ubot).join).to match(/There are no public sessions/)
        expect(buffer(to: :cbot2cu, from: :ubot).join).not_to match(/`mySessionshare`/)
      end

      it 'is sharing a session only on the channel specified' do
        send_message "chatgpt share mySessionshare <##{CBOT1CM}|>", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session \*mySessionshare\* is now shared on <##{CBOT1CM}>/i)
        send_message "chatgpt public sessions", from: :user2, to: :cbot2cu
        sleep seconds_to_wait
        expect(buffer(to: :cbot2cu, from: :ubot).join).to match(/There are no public sessions/)
        expect(bufferc(to: :cbot2cu, from: :ubot).join).not_to match(/`mySessionshare`/)
        send_message "chatgpt shared sessions", from: :user2, to: :cbot2cu
        sleep seconds_to_wait
        expect(buffer(to: :cbot2cu, from: :ubot).join).not_to match(/`mySessionshare`/)
        send_message "chatgpt use smartbotuser1 mySessionshare", from: :user2, to: :cbot2cu
        sleep seconds_to_wait
        expect(bufferc(to: :cbot2cu, from: :ubot).join).not_to match(/The user \*smartbotuser1\* doesn't exist/i)
        send_message("chatgpt shared sessions", from: :user2, to: channel)
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/`mySessionshare`/)
        send_message "chatgpt use smartbotuser1 mySessionshare", from: :user2, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/Session mySessionshare \(smartbotuser1\) copied to mySessionshare/i)
        expect(bufferc(to: channel, from: :ubot).join).to match(/Now you can call `\^chatGPT mySessionshare`/i)
        send_message "chatgpt mySessionshare", from: :user2, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/10/)
        send_message "?and plus 2", from: :user2, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/12/)
      end

      it 'is stopping sharing a session only on the channel specified' do
        send_message "chatgpt share mySessionshare <##{CBOT1CM}|>", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session \*mySessionshare\* is now shared on <##{CBOT1CM}>/i)
        send_message "chatgpt share mySessionshare <##{CBOT2CU}|>", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session \*mySessionshare\* is now shared on <##{CBOT2CU}>/i)
        send_message "chatgpt shared sessions", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/`mySessionshare`/)
        send_message "chatgpt shared sessions", from: user, to: :cbot2cu
        sleep seconds_to_wait
        expect(bufferc(to: :cbot2cu, from: :ubot).join).to match(/`mySessionshare`/)
        send_message "chatgpt stop sharing mySessionshare <##{CBOT2CU}|>", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session \*mySessionshare\* is no longer shared on <##{CBOT2CU}>/i)
        send_message "chatgpt shared sessions", from: user, to: :cbot2cu
        sleep seconds_to_wait
        expect(bufferc(to: :cbot2cu, from: :ubot).join).not_to match(/`mySessionshare`/)
        send_message "chatgpt shared sessions", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/`mySessionshare`/)
      end

    end
  end
end
