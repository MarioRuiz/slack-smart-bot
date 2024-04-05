class SlackSmartBot
  module Utils
    module Encryption
      def self.encrypt(data, config)
        if config.encrypt
          require "openssl"
          require "base64"
          if data == ''
            encrypted = ''
          else
            key, iv = Utils::Encryption.encryption_get_key_iv(config)
            cipher = OpenSSL::Cipher::Cipher.new "AES-256-CBC"
            cipher.encrypt
            cipher.key = key
            cipher.iv = iv
            encrypted = cipher.update(data) + cipher.final
            encrypted = Base64.encode64(encrypted)
            if defined?(Thread.current)
              Thread.current[:encrypted] ||= []
              Thread.current[:encrypted] << data
            end
          end
          return encrypted
        else
          return data
        end
      end
    end
  end
end
