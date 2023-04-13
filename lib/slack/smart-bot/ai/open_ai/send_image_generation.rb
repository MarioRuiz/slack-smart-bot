class SlackSmartBot
  module AI
    module OpenAI
      def self.send_image_generation(open_ai_client, message, image_size)
        require "openai"
        user = Thread.current[:user]
        #todo: personal settings size #Jal
        response = open_ai_client.images.generate(parameters: { prompt: message, size: image_size })
        if !response.body.json(:message).empty?
          return false, "*OpenAI*: #{response.body.json(:message)}"
        else
          urls = [response.body.json(:url)].flatten
          return true, urls
        end
      end
    end
  end
end
