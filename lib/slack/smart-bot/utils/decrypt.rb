class SlackSmartBot
  def decrypt(data)
    if config.encrypt
      require "openssl"
      require "base64"

      key, iv = encryption_get_key_iv()
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
