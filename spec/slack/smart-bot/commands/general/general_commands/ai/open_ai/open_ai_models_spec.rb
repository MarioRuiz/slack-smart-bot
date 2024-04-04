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
          if ENV['OPENAI_USE_LLM'].to_s=='true'
            send_message "?m gpt-35-turbo", from: user, to: channel
            sleep 4
            model_info = buffer(to: channel, from: :ubot).join
            expect(model_info).to match(/Info about gpt-35-turbo model/)
            expect(model_info).to match(/location/)
            expect(model_info).to match(/max_tokens/)
            expect(model_info).to match(/mode/)
          elsif ENV['OPENAI_HOST'].to_s=='true'
            send_message "?m whisper-1", from: user, to: channel
            sleep 4
            model_info = buffer(to: channel, from: :ubot).join
            expect(model_info).to match(/Info about whisper-1 model/)
            expect(model_info).to match(/id/)
            expect(model_info).to match(/object/)
            expect(model_info).to match(/"openai-internal"/)
          else #azure
            send_message "?m text-curie-001", from: user, to: channel
            sleep 4
            model_info = buffer(to: channel, from: :ubot).join
            expect(model_info).to match(/Info about text-curie-001 model/)
            expect(model_info).to match(/id/)
            expect(model_info).to match(/status/)
            expect(model_info).to match(/"deployment"/)
          end
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
