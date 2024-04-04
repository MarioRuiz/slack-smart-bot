require 'ostruct'

class SlackSmartBot

  class Config < OpenStruct
    # token [String] (default: ""): The API Slack token.
    # user_token [String] (default: ""): The Slack User token.
    # granular_token [String] (default: ""): The Slack granular token.
    # path [String] (default: "."): Path to the folder where the bot is running
    # silent [Boolean] (default: false): If true the bot will not send any message to the chat when starting or stopping
    # testing [Boolean] (default: false): Whether the bot is running in testing mode.
    # simulate [Boolean] (default: false): Whether the bot is running in simulation mode.
    # stats [Boolean] (default: false): Whether the bot should collect and log statistics.
    # allow_access [Hash] (default: {}): The access control settings for the bot.
    # on_maintenance [Boolean] (default: false): Whether the bot is on maintenance mode.
    # on_maintenance_message [String] (default: "Sorry I'm on maintenance so I cannot attend your request."): The message to send when the bot is on maintenance mode.
    # general_message [String] (default: ""): The general message added to be sent on every message the bot sends.
    # logrtm [Boolean] (default: false): Whether the bot should log all messages received and sent (RTM).
    # status_channel [String] (default: "smartbot-status"): The channel where the bot will send status messages.
    # stats_channel [String] (default: "smartbot-stats"): The channel where the bot is allowed to send statistics.
    # jira [Hash] (default: { host: "", user: "", password: "" }): The settings for Jira.
    # github [Hash] (default: , host: "https://api.github.com" }): The settings for GitHub.
    # public_holidays [Hash] (default: { api_key: "", host: "https://calendarific.com", default_calendar: '' }): The settings for public holidays.
    # encrypt [Boolean] (default: true): Whether the bot should encrypt the data.
    # encryption [Hash] (default: { key: "", iv: "" }): The settings for encryption. If not provided the bot will generate a new key and iv.
    # recover_encrypted [Boolean] (default: false): Whether the bot should recover the encrypted data in case now encrypt is set to false but data is still encrypted. This is used for testing purposes.
    # ai [Hash] (default: { open_ai: { access_token: "", host: "" }): The settings for OpenAI.
    # ai.open_ai.chat_gpt [Hash] (default: {access_token: "", host: "", model: "gpt-3.5-turbo", smartbot_model: "gpt-3.5-turbo", api_type: :openai, api_version: "", fixed_user: ''}): The settings for OpenAI ChatGPT.
    # ai.open_ai.dall_e [Hash] (default: {access_token: "", host: "", model: "", api_type: :openai, image_size: "256x256"}): The settings for OpenAI DALL-E.
    # ai.open_ai.whisper [Hash] (default: {access_token: "", host: "", model: "whisper-1", api_type: :openai}): The settings for OpenAI Whisper.
    # ai.open_ai.models [Hash] (default: {access_token: "", host: "", url: "", api_type: :openai, api_version: ""}): The settings for OpenAI Models.
    # file [String] (default: ""): The file to load the bot from.
    # masters [Array] (default: []): The list of master users.
    # team_id_masters [Array] (default: []): The list of master team_id + user ids.
    # master_channel [String] (default: ""): The Smartbot master channel.
    # channel [String] (default: ""): The Smartbot channel.
    # status_init [Symbol] (default: :on): The initial status of the bot.
    # rules_file [String] (default: ""): The file to load the rules from.
    # admins [Array] (default: []): The list of admin users.
    # team_id_admins [Array] (default: []): The list of admin team_id + user ids.
    # start_bots [Boolean] (default: true): Whether the bot should start the bots when starting.
    # ldap [Hash] (default: { host: "", port: 389, auth: {user: '', password: ''}, treebase: "dc=ds,dc=eng,dc=YOURCOMPANY,dc=com" }): The settings for LDAP. @ldap connection will be created. It will populate the sso_user_name key to 'user' searching by Slack mail specified in profile.
    # authorizations [Hash] (default: {}): The authorizations for services. for example: { confluence: {host: 'confluence.example.com', authorization: 'Bearer Adjjj3dddfj'}}
    def initialize(*args)
      super
      self.token ||= ""
      self.user_token ||= ""
      self.granular_token ||= ""

      self.path ||= "."
      self.file ||= ""
      self.rules_file ||= ""

      self.start_bots ||= true
      self.status_init ||= :on
      self.silent ||= false
      self.testing ||= false
      self.simulate ||= false
      self.logrtm ||= false

      self.masters ||= []
      self.team_id_masters ||= []
      self.admins ||= []
      self.team_id_admins ||= []

      self.stats ||= false
      self.allow_access ||= {}

      self.on_maintenance ||= false
      self.on_maintenance_message ||= "Sorry I'm on maintenance so I cannot attend your request."
      self.general_message ||= ""

      self.master_channel ||= "" # smartbot master channel
      self.channel ||= "" # smartbot channel
      self.status_channel ||= "smartbot-status"
      self.stats_channel ||= "smartbot-stats"

      self.jira ||= { host: "", user: "", password: "" }
      self.github ||= { token: "", host: "https://api.github.com" }
      self.public_holidays ||= { api_key: "", host: "https://calendarific.com", default_calendar: ""}

      self.encrypt ||= true
      self.encryption ||= { key: "", iv: "" }
      self.recover_encrypted ||= false

      self.ai ||= { open_ai: { testing: false, access_token: "", host: "", chat_gpt: {}, dall_e: {}, whisper: {}, models: {} } }
      self.ai[:open_ai][:host] = "https://#{self.ai[:open_ai][:host]}" unless self.ai[:open_ai][:host].empty? || self.ai[:open_ai][:host].start_with?("http")
      self.ai[:open_ai][:chat_gpt] ||= {}
      self.ai[:open_ai][:dall_e] ||= {}
      self.ai[:open_ai][:whisper] ||= {}
      self.ai[:open_ai][:models] ||= {}

      self.ai[:open_ai][:chat_gpt][:access_token] ||= self.ai[:open_ai][:access_token]
      self.ai[:open_ai][:dall_e][:access_token] ||= self.ai[:open_ai][:access_token]
      self.ai[:open_ai][:whisper][:access_token] ||= self.ai[:open_ai][:access_token]
      self.ai[:open_ai][:models][:access_token] ||= self.ai[:open_ai][:access_token]

      self.ai[:open_ai][:chat_gpt][:host] ||= self.ai[:open_ai][:host]
      self.ai[:open_ai][:dall_e][:host] ||= self.ai[:open_ai][:host]
      self.ai[:open_ai][:whisper][:host] ||= self.ai[:open_ai][:host]
      self.ai[:open_ai][:models][:host] ||= self.ai[:open_ai][:host]

      self.ai[:open_ai][:chat_gpt][:model] ||= "gpt-3.5-turbo"
      self.ai[:open_ai][:chat_gpt][:smartbot_model] ||= self.ai[:open_ai][:chat_gpt][:model]
      self.ai[:open_ai][:dall_e][:model] ||= ""
      self.ai[:open_ai][:whisper][:model] ||= "whisper-1"

      self.ai[:open_ai][:chat_gpt][:api_type] ||= :openai
      self.ai[:open_ai][:dall_e][:api_type] ||= :openai
      self.ai[:open_ai][:whisper][:api_type] ||= :openai
      self.ai[:open_ai][:models][:api_type] ||= self.ai[:open_ai][:chat_gpt][:api_type]

      self.ai[:open_ai][:chat_gpt][:api_version] ||= ""
      self.ai[:open_ai][:chat_gpt][:fixed_user] ||= ""
      self.ai[:open_ai][:models][:api_version] ||= self.ai[:open_ai][:chat_gpt][:api_version]

      self.ai[:open_ai][:dall_e][:image_size] ||= "256x256"

      self.ai[:open_ai][:models][:url] ||= ""

      self.ldap ||= { host: "", port: 389, auth: { user: '', password: '' }, treebase: "dc=ds,dc=eng,dc=YOURCOMPANY,dc=com" }

      self.authorizations ||= {}
    end
  end
end
