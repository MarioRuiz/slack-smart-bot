RSpec.describe SlackSmartBot, "open_ai_chat_use_model" do
  describe "open_ai chat use model" do
    describe "on channel bot" do
      channel = :cbot1cm
      user = :user1
      seconds_to_wait = ENV['OPEN_AI_SECONDS_TO_WAIT'].to_i || 3

      before(:all) do
        skip("no api key") unless ENV["OPENAI_ACCESS_TOKEN"].to_s != ""
      end

      it "use the specified model when on temporary session" do
        send_message "?? use model 0301", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Let's start a new temporary conversation. Ask me anything./)
        send_message "? hola", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/gpt-3\.5/)
      end

      it "use the specified model when on session" do
        send_message "chatgpt useModel01", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Session _<useModel01>_ model: gpt-3\.5/)
        send_message "? use model 0301", from: user, to: channel
        sleep seconds_to_wait
        expect(bufferc(to: channel, from: :ubot).join).to match(/Model for this session is now gpt-3\.5/)
      end

      it 'returns model not found' do
        send_message "?? use model wrong", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/Let's start a new temporary conversation. Ask me anything./)
        expect(buffer(to: channel, from: :ubot).join).to match(/There is no model with that name/)
      end

      it 'returns more than one model found' do
        send_message "?? use model gpt", from: user, to: channel
        sleep seconds_to_wait
        expect(buffer(to: channel, from: :ubot).join).to match(/Let's start a new temporary conversation. Ask me anything./)
        expect(buffer(to: channel, from: :ubot).join).to match(/There are more than one model with that name. Please be more specific:/)
      end


    end
  end
end
