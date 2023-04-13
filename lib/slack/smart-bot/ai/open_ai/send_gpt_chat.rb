class SlackSmartBot
  module AI
    module OpenAI
      def self.send_gpt_chat(open_ai_client, model, message)
        require "openai"
        user = Thread.current[:user]
        response = open_ai_client.chat(
          parameters: {
            model: model, # Required.
            messages: [{ role: "user", content: message }], # Required.
            temperature: 0.7,
          },
        )
        if !response.body.json(:message).empty? and response.body.json(:content).empty?
          result = response.body.json(:message)
          return false, result
        else
          result = response.body.json(:content)
          return true, result
        end
      end
    end
  end
end
