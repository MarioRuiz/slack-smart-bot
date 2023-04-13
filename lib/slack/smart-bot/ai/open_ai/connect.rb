class SlackSmartBot
  module AI
    module OpenAI
      def self.connect(ai_open_ai, general_config, personal_settings, reconnect: false)
        require "openai"
        user = Thread.current[:user]
        ai_open_ai = {} if ai_open_ai.nil?

        # ._ai to avoid to call .ai method from amazing_print
        ai_open_ai[user.name] ||= { client: nil, gpt_model: general_config._ai.open_ai.gpt_model, whisper_model: general_config._ai.open_ai.whisper_model, image_size: general_config._ai.open_ai.image_size }
        if personal_settings.key?(user.name) and personal_settings[user.name].key?("ai.open_ai.gpt_model") and
           personal_settings[user.name]["ai.open_ai.gpt_model"] != ""
          ai_open_ai[user.name][:gpt_model] = personal_settings[user.name]["ai.open_ai.gpt_model"]
        elsif general_config.key?(:ai) and general_config[:ai].key?(:open_ai) and general_config[:ai][:open_ai].key?(:gpt_model) and
              general_config[:ai][:open_ai][:gpt_model] != ""
          ai_open_ai[user.name][:gpt_model] = general_config[:ai][:open_ai][:gpt_model]
        end
        if personal_settings.key?(user.name) and personal_settings[user.name].key?("ai.open_ai.whisper_model") and
           personal_settings[user.name]["ai.open_ai.whisper_model"] != ""
          ai_open_ai[user.name][:whisper_model] = personal_settings[user.name]["ai.open_ai.whisper_model"]
        elsif general_config.key?(:ai) and general_config[:ai].key?(:open_ai) and general_config[:ai][:open_ai].key?(:whisper_model) and
              general_config[:ai][:open_ai][:whisper_model] != ""
          ai_open_ai[user.name][:whisper_model] = general_config[:ai][:open_ai][:whisper_model]
        end
        if personal_settings.key?(user.name) and personal_settings[user.name].key?("ai.open_ai.image_size") and
           personal_settings[user.name]["ai.open_ai.image_size"] != ""
          ai_open_ai[user.name][:image_size] = personal_settings[user.name]["ai.open_ai.image_size"]
        elsif general_config.key?(:ai) and general_config[:ai].key?(:open_ai) and general_config[:ai][:open_ai].key?(:image_size) and
              general_config[:ai][:open_ai][:image_size] != ""
          ai_open_ai[user.name][:image_size] = general_config[:ai][:open_ai][:image_size]
        end
        if ai_open_ai.key?(user.name) and ai_open_ai[user.name] != nil and ai_open_ai[user.name].key?(:client) and
           ai_open_ai[user.name][:client] != nil and !reconnect
          # do nothing
        elsif personal_settings.key?(user.name) and personal_settings[user.name].key?("ai.open_ai.access_token") and
              personal_settings[user.name]["ai.open_ai.access_token"].to_s != ""
          ai_open_ai[user.name].client = ::OpenAI::Client.new(access_token: personal_settings[user.name]["ai.open_ai.access_token"].to_s)
        elsif general_config.key?(:ai) and general_config[:ai].key?(:open_ai) and general_config[:ai][:open_ai].key?(:access_token) and
              general_config[:ai][:open_ai][:access_token] != ""
          ai_open_ai[user.name].client = ::OpenAI::Client.new(access_token: general_config[:ai][:open_ai][:access_token])
        else
          ai_open_ai[user.name] = nil
          message = ["You need to set the OpenAI access token in the config file or in the personal settings."]
          message << "You can get it from https://platform.openai.com/account/api-keys"
          message << "Then in case you are a master admin, you can set it in the SmartBot config file:"
          message << "    `ai: { open_ai: { access_token: 'ACCESS_TOKEN'} }`"
          message << "If you want to use your personal access token, you can set it on a DM with SmartBot in the personal settings:"
          message << "    `set personal settings ai.open_ai.access_token ACCESS_TOKEN`"
          message << "By default we will be using the gpt_model #{general_config._ai.open_ai.gpt_model}. You can change it in the config file or in personal settings:"
          message << "    `set personal settings ai.open_ai.gpt_model gpt-4`"
          message << "By default we will be using the whisper_model #{general_config._ai.open_ai.whisper_model}. You can change it in the config file or in personal settings:"
          message << "    `set personal settings ai.open_ai.whisper_model whisper-1`"
          message << "You can also change the image size in the config file or in personal settings:"
          message << "    `set personal settings ai.open_ai.image_size 512x512`"
          return ai_open_ai, message.join("\n")
        end
        return ai_open_ai, ''
      end
    end
  end
end
