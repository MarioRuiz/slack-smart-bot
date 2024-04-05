class SlackSmartBot
  module AI
    module OpenAI
      def self.send_image_edit(open_api_client, image, message, size: "")
        #todo: add size personal settings
        require "openai"
        user = Thread.current[:user]

        if size == ""
          response = open_ai_client.images.edit(parameters: { image: image, prompt: message })
        else
          response = open_api_client.images.edit(parameters: { image: image, prompt: message, size: size })
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
