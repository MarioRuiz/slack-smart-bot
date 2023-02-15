class SlackSmartBot
  def encrypt(data)
    require "openssl"
    require "base64"

    key, iv = encryption_get_key_iv()
    cipher = OpenSSL::Cipher::Cipher.new "AES-256-CBC"
    cipher.encrypt
    cipher.key = key
    cipher.iv = iv
    encrypted = cipher.update(data) + cipher.final
    encrypted = Base64.encode64(encrypted)
    return encrypted
  end
end
