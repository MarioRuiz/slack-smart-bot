class SlackSmartBot
  module Utils
    module Encryption
      def self.decrypt(data, config)
        if config.encrypt
          require "openssl"
          require "base64"

          key, iv = Utils::Encryption.encryption_get_key_iv(config)
          encrypted = Base64.decode64(data)
          cipher = OpenSSL::Cipher.new("AES-256-CBC")
          cipher.decrypt
          cipher.key = key
          cipher.iv = iv
          plain = cipher.update(encrypted) + cipher.final
          return plain
        else
          return data
        end
      end
    end
  end
end
