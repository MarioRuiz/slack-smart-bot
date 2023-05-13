RSpec.describe SlackSmartBot, "open_ai_models" do
    describe "open_ai models" do
      describe "on direct message" do
        channel = DIRECT.user1.ubot
        user = :user1

        before(:all) do
            skip("no api key") unless ENV["OPENAI_ACCESS_TOKEN"].to_s != ""
        end

        it 'displays the list of models' do
            send_message "?m", from: user, to: channel
            sleep 3
            expect(buffer(to: channel, from: :ubot).join).to match(/Here are the models available for use/)
            expect(buffer(to: channel, from: :ubot).join).to match(/gpt/)
            expect(buffer(to: channel, from: :ubot).join).to match(/set personal settings ai.open_ai.chat_gpt.model MODEL_NAME/)
            expect(buffer(to: channel, from: :ubot).join).to match(/set personal settings ai.open_ai.whisper.model MODEL_NAME/)   
            expect(buffer(to: channel, from: :ubot).join).to match(/If you want to use a model by default, you can use on a DM with the SmartBot the command/)
            expect(buffer(to: channel, from: :ubot).join).to match(/To start a chatGPT session using a specific model: `\^chatgpt SESSION_NAME MODEL_NAME`/)
        end

        it 'displays the info of a model' do
            send_message "?m curie", from: user, to: channel
            sleep 4
            expect(buffer(to: channel, from: :ubot).join).to match(/Info about curie model/)
            expect(buffer(to: channel, from: :ubot).join).to match(/"id"/)
            expect(buffer(to: channel, from: :ubot).join).to match(/"curie"/)
            expect(buffer(to: channel, from: :ubot).join).to match(/"permission"/)
        end

        it 'displays only the chatgpt models' do
          send_message "chatgpt models", from: user, to: channel
          sleep 4
          expect(buffer(to: channel, from: :ubot).join).to match(/Here are the chatgpt models available for use/)
          expect(buffer(to: channel, from: :ubot).join).to match(/gpt/)
          expect(buffer(to: channel, from: :ubot).join).to match(/set personal settings ai.open_ai.chat_gpt.model MODEL_NAME/)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/set personal settings ai.open_ai.whisper.model MODEL_NAME/)   
          expect(buffer(to: channel, from: :ubot).join).to match(/If you want to use a model by default, you can use on a DM with the SmartBot the command/)
          expect(buffer(to: channel, from: :ubot).join).to match(/To start a chatGPT session using a specific model: `\^chatgpt SESSION_NAME MODEL_NAME`/)
        end

        it 'displays only the chatgpt models when ?m chatgpt' do
          send_message "?m chatgpt", from: user, to: channel
          sleep 4
          expect(buffer(to: channel, from: :ubot).join).to match(/Here are the chatgpt models available for use/)
          expect(buffer(to: channel, from: :ubot).join).to match(/gpt/)
          expect(buffer(to: channel, from: :ubot).join).to match(/set personal settings ai.open_ai.chat_gpt.model MODEL_NAME/)
          expect(buffer(to: channel, from: :ubot).join).not_to match(/set personal settings ai.open_ai.whisper.model MODEL_NAME/)   
          expect(buffer(to: channel, from: :ubot).join).to match(/If you want to use a model by default, you can use on a DM with the SmartBot the command/)
          expect(buffer(to: channel, from: :ubot).join).to match(/To start a chatGPT session using a specific model: `\^chatgpt SESSION_NAME MODEL_NAME`/)
        end
      end
    end
end
  