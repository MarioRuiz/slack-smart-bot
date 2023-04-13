class SlackSmartBot
  module AI
    module OpenAI
      def self.models(open_ai_client, model='')
        require "openai"
        user = Thread.current[:user]
        if model.empty?
          response = open_ai_client.models.list
          result = response.body.json().data.id.sort.join("\n")
        else
          response = open_ai_client.models.retrieve(id: model)
          result = response.body
        end
        if !response.body.json(:message).empty? and response.body.json(:content).empty?
          result = response.body.json(:message)
        end
        return result
      end
    end
  end
end
