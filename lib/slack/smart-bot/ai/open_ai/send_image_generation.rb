class SlackSmartBot
  module AI
    module OpenAI
      def self.send_image_generation(open_ai_client, message, image_size)
        require "openai"
        user = Thread.current[:user]
        response = open_ai_client.images.generate(parameters: { prompt: message, size: image_size })
        response = response.to_json
        if !response.json(:message).empty?
          return false, "*OpenAI*: #{response.json(:message)}"
        else
          urls = response.json(:url)
          return true, urls
        end
      end
    end
  end
end
