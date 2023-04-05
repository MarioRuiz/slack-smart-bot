class SlackSmartBot
  def encrypt(data)
    if config.encrypt 
      require "openssl"
      require "base64"

      key, iv = encryption_get_key_iv()
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
      return encrypted
    else
      return data
    end
  end
end
