class SlackSmartBot
  def update_openai_sessions(session_name='', user_name: '')
    require 'yaml'
    user_name = Thread.current[:user].name if user_name == ''
    unless Dir.exist?("#{config.path}/openai/#{user_name}")
      Dir.mkdir("#{config.path}/openai/#{user_name}")
    end
    
    file_name = File.join(config.path, "openai", "o_#{user_name}.yaml")
    data = @open_ai[user_name].deep_copy
    if data.key?(:chat_gpt) and data[:chat_gpt].key?(:sessions)
      data[:chat_gpt][:sessions].delete('') #temporary session
    end
    File.open(file_name, 'w') {|file|
      file.flock(File::LOCK_EX)
      file.write(Utils::Encryption.encrypt(data.to_yaml, config))
      file.flock(File::LOCK_UN)
    }
    @datetime_open_ai_file[file_name] = File.mtime(file_name)
    if session_name != ''
      if !@open_ai[user_name][:chat_gpt][:sessions].key?(session_name) #delete file if session is not longer available
        if File.exist?(File.join(config.path, "openai", "#{user_name}/session_#{session_name}.txt"))
          File.delete(File.join(config.path, "openai", "#{user_name}/session_#{session_name}.txt"))
        end
      else
        file_name = File.join(config.path, "openai", "#{user_name}/session_#{session_name}.txt")
        content = @ai_gpt[user_name][session_name].join("\n").force_encoding("UTF-8")
        File.open(file_name, 'w') {|file|
            file.flock(File::LOCK_EX)
          file.write(Utils::Encryption.encrypt(content, config))
          file.flock(File::LOCK_UN)
        }
      end
    end
  end
end
