class SlackSmartBot
  def get_openai_sessions(session_name='', user_name: '')
    require 'yaml'
    files = Dir.glob(File.join(config.path, "openai", "o_*.yaml"))
    @datetime_open_ai_file ||= {}
    files.each do |file|
      if !defined?(@datetime_open_ai_file) or !@datetime_open_ai_file.key?(file) or @datetime_open_ai_file[file] != File.mtime(file)
        opean_ai_user = YAML.load(Utils::Encryption.decrypt(File.read(file), config))
        @open_ai[File.basename(file).gsub("o_","").gsub(".yaml","")] = opean_ai_user
        @datetime_open_ai_file[file] = File.mtime(file)
      end
    end
    if session_name != ''
      user_name = Thread.current[:user].name if user_name == ''
      file_name = File.join(config.path, "openai", "#{user_name}/session_#{session_name}.txt")
      if File.exist?(file_name)
        @ai_gpt ||= {}
        @ai_gpt[user_name] ||= {}
        content = File.read(file_name)
        @ai_gpt[user_name][session_name] = Utils::Encryption.decrypt(content, config).force_encoding("UTF-8").split("\n")
      end
    end
  end
end