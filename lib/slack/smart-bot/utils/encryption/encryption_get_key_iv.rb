class SlackSmartBot
  module Utils
    module Encryption
      def self.encryption_get_key_iv(config)
        if defined?(@encryption_key_built)
          key = @encryption_key_built
          iv = @encryption_iv_built
        else
          if config.key?(:encryption) and config.encryption.key?(:key) and config.encryption.key?(:iv)
            key = config[:encryption][:key]
            iv = config[:encryption][:iv]
          else
            key = (Socket.gethostname + config.token.reverse)[0..49]
            iv = config.token[0..15]
          end

          #Convert from hex to raw bytes:
          key = [key].pack("H*")
          #Pad with zero bytes to correct length:
          key << ("\x00" * (32 - key.length))

          #Convert from hex to raw bytes:
          iv = [iv].pack("H*")
          #Pad with zero bytes to correct length:
          iv << ("\x00" * (16 - iv.length))
          @encryption_key_built = key
          @encryption_iv_built = iv
        end
        return key, iv
      end
    end
  end
end
