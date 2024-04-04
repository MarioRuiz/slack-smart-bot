class SlackSmartBot
  module AI
    module OpenAI
      def self.connect(ai_open_ai, general_config, personal_settings, reconnect: false, service: :chat_gpt)
        require "openai"
        require "nice_http"
        user = Thread.current[:user]
        team_id_user = Thread.current[:team_id_user]

        ai_open_ai = {} if ai_open_ai.nil?
        ai_open_ai_user = {}

        # ._ai to avoid to call .ai method from amazing_print
        ai_open_ai_user = {
          host: general_config._ai.open_ai.host,
          access_token: general_config._ai.open_ai.access_token,
          models: {
            client: nil,
            host: general_config._ai.open_ai.models.host,
            access_token: general_config._ai.open_ai.models.access_token,
            url: general_config._ai.open_ai.models.url,
            api_type: general_config._ai.open_ai.models.api_type,
            api_version: general_config._ai.open_ai.models.api_version,
          },
          chat_gpt: {
            client: nil,
            host: general_config._ai.open_ai.chat_gpt.host,
            access_token: general_config._ai.open_ai.chat_gpt.access_token,
            model: general_config._ai.open_ai.chat_gpt.model,
            smartbot_model: general_config._ai.open_ai.chat_gpt.smartbot_model,
            api_type: general_config._ai.open_ai.chat_gpt.api_type,
            api_version: general_config._ai.open_ai.chat_gpt.api_version,
            fixed_user: general_config._ai.open_ai.chat_gpt.fixed_user, #for testing purposes
          },
          dall_e: {
            client: nil,
            host: general_config._ai.open_ai.dall_e.host,
            access_token: general_config._ai.open_ai.dall_e.access_token,
            image_size: general_config._ai.open_ai.dall_e.image_size,
            model: general_config._ai.open_ai.dall_e.model,
          },
          whisper: {
            client: nil,
            host: general_config._ai.open_ai.whisper.host,
            access_token: general_config._ai.open_ai.whisper.access_token,
            model: general_config._ai.open_ai.whisper.model,
          },
        }
        if personal_settings.key?(team_id_user) and personal_settings[team_id_user].key?("ai.open_ai.host") and
           personal_settings[team_id_user]["ai.open_ai.host"] != ""
          ai_open_ai_user[:host] = personal_settings[team_id_user]["ai.open_ai.host"]
          ai_open_ai_user[:chat_gpt][:host] = ai_open_ai_user[:host]
          ai_open_ai_user[:dall_e][:host] = ai_open_ai_user[:host]
          ai_open_ai_user[:whisper][:host] = ai_open_ai_user[:host]
          ai_open_ai_user[:models][:host] = ai_open_ai_user[:host]
        end

        if personal_settings.key?(team_id_user) and personal_settings[team_id_user].key?("ai.open_ai.access_token") and
           personal_settings[team_id_user]["ai.open_ai.access_token"] != ""
          ai_open_ai_user[:access_token] = personal_settings[team_id_user]["ai.open_ai.access_token"]
          ai_open_ai_user[:chat_gpt][:access_token] = ai_open_ai_user[:access_token]
          ai_open_ai_user[:dall_e][:access_token] = ai_open_ai_user[:access_token]
          ai_open_ai_user[:whisper][:access_token] = ai_open_ai_user[:access_token]
          ai_open_ai_user[:models][:access_token] = ai_open_ai_user[:access_token]
        end

        if personal_settings.key?(team_id_user) and personal_settings[team_id_user].key?("ai.open_ai.chat_gpt.model") and
           personal_settings[team_id_user]["ai.open_ai.chat_gpt.model"] != ""
          ai_open_ai_user[:chat_gpt][:model] = personal_settings[team_id_user]["ai.open_ai.chat_gpt.model"]
        end
        if personal_settings.key?(team_id_user) and personal_settings[team_id_user].key?("ai.open_ai.chat_gpt.smartbot_model") and
           personal_settings[team_id_user]["ai.open_ai.chat_gpt.smartbot_model"] != ""
          ai_open_ai_user[:chat_gpt][:smartbot_model] = personal_settings[team_id_user]["ai.open_ai.chat_gpt.smartbot_model"]
        end

        if personal_settings.key?(team_id_user) and personal_settings[team_id_user].key?("ai.open_ai.whisper.model") and
           personal_settings[team_id_user]["ai.open_ai.whisper.model"] != ""
          ai_open_ai_user[:whisper][:model] = personal_settings[team_id_user]["ai.open_ai.whisper.model"]
        end
        if personal_settings.key?(team_id_user) and personal_settings[team_id_user].key?("ai.open_ai.dall_e.image_size") and
           personal_settings[team_id_user]["ai.open_ai.dall_e.image_size"] != ""
          ai_open_ai_user[:dall_e][:image_size] = personal_settings[team_id_user]["ai.open_ai.dall_e.image_size"]
        end

        if personal_settings.key?(team_id_user) and personal_settings[team_id_user].key?("ai.open_ai.chat_gpt.host") and
           personal_settings[team_id_user]["ai.open_ai.chat_gpt.host"] != ""
          ai_open_ai_user[:chat_gpt][:host] = personal_settings[team_id_user]["ai.open_ai.chat_gpt.host"]
        end
        if personal_settings.key?(team_id_user) and personal_settings[team_id_user].key?("ai.open_ai.dall_e.host") and
           personal_settings[team_id_user]["ai.open_ai.dall_e.host"] != ""
          ai_open_ai_user[:dall_e][:host] = personal_settings[team_id_user]["ai.open_ai.dall_e.host"]
        end
        if personal_settings.key?(team_id_user) and personal_settings[team_id_user].key?("ai.open_ai.whisper.host") and
           personal_settings[team_id_user]["ai.open_ai.whisper.host"] != ""
          ai_open_ai_user[:whisper][:host] = personal_settings[team_id_user]["ai.open_ai.whisper.host"]
        end

        if personal_settings.key?(team_id_user) and personal_settings[team_id_user].key?("ai.open_ai.chat_gpt.access_token") and
           personal_settings[team_id_user]["ai.open_ai.chat_gpt.access_token"] != ""
          ai_open_ai_user[:chat_gpt][:access_token] = personal_settings[team_id_user]["ai.open_ai.chat_gpt.access_token"]
        end
        if personal_settings.key?(team_id_user) and personal_settings[team_id_user].key?("ai.open_ai.dall_e.access_token") and
           personal_settings[team_id_user]["ai.open_ai.dall_e.access_token"] != ""
          ai_open_ai_user[:dall_e][:access_token] = personal_settings[team_id_user]["ai.open_ai.dall_e.access_token"]
        end
        if personal_settings.key?(team_id_user) and personal_settings[team_id_user].key?("ai.open_ai.whisper.access_token") and
           personal_settings[team_id_user]["ai.open_ai.whisper.access_token"] != ""
          ai_open_ai_user[:whisper][:access_token] = personal_settings[team_id_user]["ai.open_ai.whisper.access_token"]
        end

        if personal_settings.key?(team_id_user) and personal_settings[team_id_user].key?("ai.open_ai.chat_gpt.api_type") and
           personal_settings[team_id_user]["ai.open_ai.chat_gpt.api_type"] != ""
          ai_open_ai_user[:chat_gpt][:api_type] = personal_settings[team_id_user]["ai.open_ai.chat_gpt.api_type"]
        end
        if personal_settings.key?(team_id_user) and personal_settings[team_id_user].key?("ai.open_ai.chat_gpt.api_version") and
           personal_settings[team_id_user]["ai.open_ai.chat_gpt.api_version"] != ""
          ai_open_ai_user[:chat_gpt][:api_version] = personal_settings[team_id_user]["ai.open_ai.chat_gpt.api_version"]
        end
        if personal_settings.key?(team_id_user) and personal_settings[team_id_user].key?("ai.open_ai.models.host") and
            personal_settings[team_id_user]["ai.open_ai.models.host"] != ""
          ai_open_ai_user[:models][:host] = personal_settings[team_id_user]["ai.open_ai.models.host"]
        end
        if personal_settings.key?(team_id_user) and personal_settings[team_id_user].key?("ai.open_ai.models.access_token") and
            personal_settings[team_id_user]["ai.open_ai.models.access_token"] != ""
          ai_open_ai_user[:models][:access_token] = personal_settings[team_id_user]["ai.open_ai.models.access_token"]
        end
        if personal_settings.key?(team_id_user) and personal_settings[team_id_user].key?("ai.open_ai.models.url") and
            personal_settings[team_id_user]["ai.open_ai.models.url"] != ""
          ai_open_ai_user[:models][:url] = personal_settings[team_id_user]["ai.open_ai.models.url"]
        end

        host = ai_open_ai_user[service].host
        access_token = ai_open_ai_user[service].access_token

        ai_open_ai[team_id_user] ||= ai_open_ai_user.deep_copy

        if ai_open_ai.key?(team_id_user) and ai_open_ai[team_id_user] != nil and ai_open_ai[team_id_user][service].key?(:client) and
           ai_open_ai[team_id_user][service][:client] != nil and !reconnect
          # do nothing, we already have a client and we don't want to reconnect
        elsif access_token.to_s != ""
          ai_open_ai[team_id_user][service] = ai_open_ai_user[service].deep_copy
          if host == ""
            ai_open_ai[team_id_user][service][:client] = ::OpenAI::Client.new(uri_base: "https://api.openai.com/", access_token: access_token, request_timeout: 300)
          else
            if ai_open_ai_user[service].key?(:url) and ai_open_ai_user[service][:url] != ""
              ai_open_ai[team_id_user][service][:client] = NiceHttp.new(host: host, headers: { 'Authorization': "Bearer #{ai_open_ai_user[service][:access_token]}" }, ssl: true, timeout: (30))
            elsif ai_open_ai_user[service].key?(:api_type) and ai_open_ai_user[service][:api_type] == :openai_azure
              if general_config._ai.open_ai.key?(:testing) and general_config._ai.open_ai.testing #and !general_config.simulate #todo: check
                log = "#{general_config.path}/logs/chat_gpt_azure_#{team_id_user}.log"
              else
                log = :no
              end
              ai_open_ai[team_id_user][service][:client] = NiceHttp.new(host: host, headers: { 'api-key': access_token }, ssl: true, timeout: (30), log: log)
            else
              ai_open_ai[team_id_user][service][:client] = ::OpenAI::Client.new(uri_base: host, access_token: access_token, request_timeout: 300)
            end
          end
        else
          ai_open_ai[team_id_user] = nil
          message = ["You need to set the OpenAI access token in the config file or in the personal settings."]
          message << "You can get it from https://platform.openai.com/account/api-keys"
          message << "If you want to use your personal access token, you can set it on a DM with SmartBot in the personal settings:"
          message << "    `set personal settings ai.open_ai.#{service}.access_token ACCESS_TOKEN`"
          if service == :chat_gpt
            message << "By default we will be using the chatgpt model #{general_config._ai.open_ai.chat_gpt.model}. You can change it in the config file or in personal settings:"
            message << "    `set personal settings ai.open_ai.chat_gpt.model gpt-4-0314`"
            message << "For specifying the model for ChatGPT on REPLs: `set personal settings ai.open_ai.chat_gpt.smartbot_model gpt-4-0314`"
          elsif service == :whisper
            message << "By default we will be using the whisper model #{general_config._ai.open_ai.whisper.model}. You can change it in the config file or in personal settings:"
            message << "    `set personal settings ai.open_ai.whisper.model whisper-1`"
          elsif service == :dall_e
            message << "You can also change the image size in the config file or in personal settings:"
            message << "    `set personal settings ai.open_ai.dall_e.image_size 512x512`"
          end
          message << "In case you are a master admin, you can set it in the SmartBot config file:"
          message << "    `ai: { open_ai: { #{service}: { access_token: 'ACCESS_TOKEN'} } }`"
          return ai_open_ai, message.join("\n")
        end
        return ai_open_ai, ""
      end
    end
  end
end
