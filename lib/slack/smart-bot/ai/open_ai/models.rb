class SlackSmartBot
  module AI
    module OpenAI
      def self.models(open_ai_client, chat_gpt_config, model='')
        require "openai"
        require 'amazing_print'
        user = Thread.current[:user]
        if model.empty?
          if open_ai_client.is_a?(NiceHttp) #azure
            resp = open_ai_client.get("/openai/deployments?api-version=#{chat_gpt_config.api_version}")
            models = resp.body.json(:id)
            #list.select!{|i| i.include?('gpt-')} #Jal
          else
            response = open_ai_client.models.list
            models = []
            response.data.each do |model|
              models << model["id"]
            end
          end
          return models.uniq.sort.join("\n")
        else
          if open_ai_client.is_a?(NiceHttp) #azure
            resp = open_ai_client.get("/openai/deployments/#{model}?api-version=#{chat_gpt_config.api_version}")
            response = resp.body.json()     
          else
            response = open_ai_client.models.retrieve(id: model)
          end
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
