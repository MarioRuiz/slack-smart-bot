class SlackSmartBot
  module AI
    module OpenAI
      def self.send_image_variation(open_ai_client, image, variations, size: "")
        #todo: add size personal settings
        require "openai"
        user = Thread.current[:user]
        if size == ""
          response = open_ai_client.images.variations(parameters: { image: image, n: variations })
        else
          response = open_ai_client.images.variations(parameters: { image: image, n: variations, size: size })
        end
        response = response.to_json
        if !response.json(:message).empty?
          return false, "*OpenAI*: #{response.json(:message)}"
        else
          urls = [response.json(:url)].flatten
          return true, urls
        end
      end
    end
  end
end
