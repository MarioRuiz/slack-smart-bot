class SlackSmartBot
  module AI
    module OpenAI
      def self.send_gpt_chat(open_ai_client, model, message, chat_gpt_config)
        require "openai"
        require 'nice_http'
        user = Thread.current[:user]
        if user.key?(:sso_user_name)
          user_name = user.sso_user_name
        else
          user_name = user.name
        end
        parameters = {
          model: model, # Required.
          messages: [{ role: "user", content: message }], # Required.
          temperature: 0.7,
          user: user_name
        }
        parameters.user = chat_gpt_config.fixed_user if chat_gpt_config.fixed_user.to_s != ""
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
          begin
            response = open_ai_client.chat(parameters: parameters)
            response = response.to_json
          rescue Exception => e
            response = e.response
            if !response.nil? and response.status == 403 and response.body.error.message.to_s.include?("You must pass a valid 'user'")
              response.body.error.message += "\nThe user on Slack is: #{user.name}\nYou have to go to your Profile Slack Account on a browser. Then go to Settings.\nNow go to Username and click on expand, change the name to your SSO name and click on Save"
            end
            if response.nil?
              response = {message: e.message}
            else
              response = response.to_json
            end
          end
        end
        if response.nil?
          result = "No response from the AI. Please contact the SmartBot administrator."
          return false, result
        elsif response.is_a?(Hash) and response.key?(:message) and !response.key?(:content)
          result = response[:message]
          return false, result
        elsif !response.json(:message).empty? and response.json(:content).empty?
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
