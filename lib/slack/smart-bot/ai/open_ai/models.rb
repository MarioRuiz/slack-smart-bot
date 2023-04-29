class SlackSmartBot
  module AI
    module OpenAI
      def self.models(open_ai_client, model='')
        require "openai"
        require 'amazing_print'
        user = Thread.current[:user]
        if model.empty?
          response = open_ai_client.models.list
          models = []
          response.data.each do |model|
            models << model["id"]
          end
          return models.uniq.sort.join("\n")
        else
          response = open_ai_client.models.retrieve(id: model)
          result = response.ai
        end
        response = response.to_json
        if !response.json(:message).empty? and response.json(:content).empty?
          result = response.json(:message)
        end
        return result
      end
    end
  end
end
