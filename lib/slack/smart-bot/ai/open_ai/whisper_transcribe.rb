class SlackSmartBot
  module AI
    module OpenAI
      def self.whisper_transcribe(open_ai_client, model, file)
        require "openai"
        user = Thread.current[:user]
        response = open_ai_client.transcribe(
          parameters: {
            model: model, # Required.
            file: File.open(file, "rb"),
          },
        )
        response = response.to_json
        if !response.json(:message).empty?
          return false, response.json(:message)
        else
          return true, response.json(:text)
        end
      end
    end
  end
end
