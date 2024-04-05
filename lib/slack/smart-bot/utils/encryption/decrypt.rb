class SlackSmartBot
  module Utils
    module Encryption
      def self.decrypt(data, config)
        if config.encrypt or (config.key?(:recover_encrypted) and config[:recover_encrypted])
          require "openssl"
          require "base64"
          if data == ''
            plain = ''
          else
            begin
              key, iv = Utils::Encryption.encryption_get_key_iv(config)
              encrypted = Base64.decode64(data)
              cipher = OpenSSL::Cipher.new("AES-256-CBC")
              cipher.decrypt
              cipher.key = key
              cipher.iv = iv
              plain = cipher.update(encrypted) + cipher.final
            rescue Exception => stack
              return data
            end
          end            
          return plain
        else
          return data
        end
      end
    end
  end
end
