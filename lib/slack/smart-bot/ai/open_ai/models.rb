class SlackSmartBot
  module AI
    module OpenAI
      def self.models(open_ai_client, models_config, model='', return_response: false)
        require "openai"
        require 'amazing_print'
        user = Thread.current[:user]
        if model.empty? or model == 'chatgpt'
          if open_ai_client.is_a?(NiceHttp) and models_config.url != ""
            resp = open_ai_client.get(models_config.url)
            models = resp.body.json(:model_name)
            models.select!{|i| i.include?('gpt-')} if model == 'chatgpt'
          elsif open_ai_client.is_a?(NiceHttp) #azure
            resp = open_ai_client.get("/openai/deployments?api-version=#{models_config.api_version}")
            models = resp.body.json(:id)
            models.select!{|i| i.include?('gpt-')} if model == 'chatgpt'
          else
            response = open_ai_client.models.list
            models = []
            response.data.each do |model|
              models << model["id"]
            end
            models.select!{|i| i.include?('gpt-')} if model == 'chatgpt'
          end
          if return_response
            return models.uniq.sort
          else
            return models.uniq.sort.join("\n")
          end
        else
          response_obj = {}
          if open_ai_client.is_a?(NiceHttp) and models_config.url != ""
            resp = open_ai_client.get(models_config.url)
            result = {}
            resp.data.json.data.each do |m|
              if m[:model_name].to_s == model
                result = m
                break
              end
            end
            if result.empty?
              response = {message: "Model not found"}
              response_obj = response
            else
              response = {message: ''}
              result[:model_info].each do |k,v|
                response.message += "#{k}: #{v}\n"
              end
              response_obj = result[:model_info]
            end
          elsif open_ai_client.is_a?(NiceHttp) #azure
            resp = open_ai_client.get("/openai/deployments/#{model}?api-version=#{models_config.api_version}")
            response = resp.body.json()
            response_obj = response
          else
            response = open_ai_client.models.retrieve(id: model)
            response_obj = response
          end
          result = response.ai
        end
        response = response.to_json
        if !response.json(:message).empty? and response.json(:content).empty?
          result = response.json(:message)
        end
        if return_response
          return response_obj
        else
          return result
        end
      end
    end
  end
end
