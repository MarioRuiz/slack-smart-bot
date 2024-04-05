class SlackSmartBot
  def get_openai_sessions(session_name='', team_id: '', user_name: '')
    require 'yaml'
    unless Thread.current[:user].nil?
      user_name = Thread.current[:user].name if user_name == ''
      team_id = Thread.current[:user].team_id if team_id == ''
      team_id_user = team_id + "_" + user_name
    end

    # get folders on openai folder
    folders = Dir.glob(File.join(config.path, "openai", "*")).select {|f| File.directory? f}
    # get files on every team folder
    files = []
    folders.each do |folder|
      files += Dir.glob(File.join(folder, "o_*.yaml"))
    end
    @datetime_open_ai_file ||= {}
    
    files.each do |file|
      if !defined?(@datetime_open_ai_file) or !@datetime_open_ai_file.key?(file) or @datetime_open_ai_file[file] != File.mtime(file)
        opean_ai_user = YAML.load(Utils::Encryption.decrypt(File.read(file), config))
        #user_file will be the team_id _ + the user name
        user_team_id = File.basename(File.dirname(file))
        user_file = user_team_id + "_" + File.basename(file).gsub("o_","").gsub(".yaml","")
        
        if @open_ai.key?(user_file) and @open_ai[user_file].key?(:chat_gpt) and @open_ai[user_file][:chat_gpt].key?(:sessions) and
          @open_ai[user_file][:chat_gpt][:sessions].key?("")
          temp_session = @open_ai[user_file][:chat_gpt][:sessions][""].deep_copy 
        else
          temp_session = nil
        end
        @open_ai[user_file] = opean_ai_user
        @open_ai[user_file][:chat_gpt][:sessions][""] = temp_session unless temp_session.nil?
        @datetime_open_ai_file[file] = File.mtime(file)
      end
    end
    if session_name != ''
      file_name = File.join(config.path, "openai", "#{team_id}/#{user_name}/session_#{session_name}.txt")
      if File.exist?(file_name)
        @ai_gpt ||= {}
        @ai_gpt[team_id_user] ||= {}
        content = File.read(file_name)
        @ai_gpt[team_id_user][session_name] = Utils::Encryption.decrypt(content, config).force_encoding("UTF-8").split("\n")
      end
    end
  end
end
