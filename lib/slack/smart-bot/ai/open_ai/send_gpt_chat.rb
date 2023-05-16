class SlackSmartBot
  module AI
    module OpenAI
      def self.send_gpt_chat(open_ai_client, model, message, chat_gpt_config)
        require "openai"
        require 'nice_http'
        user = Thread.current[:user]
        parameters = {
          model: model, # Required.
          messages: [{ role: "user", content: message }], # Required.
          temperature: 0.7,
        }
        if open_ai_client.is_a?(NiceHttp)
          begin 
            response = {}
            tries = 0
            while (!response.key?(:data) or response.data.nil? or response.data.empty? ) and tries < 10
              begin
                request = {
                  path: "/openai/deployments/#{model}/chat/completions?api-version=#{chat_gpt_config.api_version}",
                  data: parameters
                }
                response = open_ai_client.post(request)
              rescue Exception => exception
                response = {message: exception.message}.to_json
              end
              tries += 1
              sleep 1 if !response.key?(:data) or response.data.nil? or response.data.empty? #wait a second before trying again
            end
            response.data = { message: ""}.to_json if !response.key?(:data) or response.data.nil? or response.data.empty?
            response = response.data
          rescue Exception => exception
            response = {message: exception.message}.to_json
          end
        else
          response = open_ai_client.chat(parameters: parameters)
          response = response.to_json
        end

        if !response.json(:message).empty? and response.json(:content).empty?
          result = response.json(:message)
          return false, result
        elsif !response.json(:error).empty? and !response.json(:code).empty?
          result = response.json(:code)
          return false, result
        elsif !response.json(:error).empty?
          result = response.json(:error).to_s
          return false, result
        else
          result = response.json(:content)
          return true, result
        end
      end
    end
  end
end
