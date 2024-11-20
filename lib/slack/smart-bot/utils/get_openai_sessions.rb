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
        open_ai_user = YAML.load(Utils::Encryption.decrypt(File.read(file), config))
        #user_file will be the team_id _ + the user name
        user_team_id = File.basename(File.dirname(file))
        user_file = user_team_id + "_" + File.basename(file).gsub("o_","").gsub(".yaml","")

        if @open_ai.key?(user_file) and @open_ai[user_file].key?(:chat_gpt) and @open_ai[user_file][:chat_gpt].key?(:sessions) and
          @open_ai[user_file][:chat_gpt][:sessions].key?("")
          temp_session = @open_ai[user_file][:chat_gpt][:sessions][""].deep_copy
        else
          temp_session = nil
        end
        @open_ai[user_file] = open_ai_user
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
        #The file contains an array of hashes with the messages
        #read it and store it as ruby code
        session = Utils::Encryption.decrypt(content, config).force_encoding("UTF-8")
        session_new_format = []
        if session.to_s.match?(/^Me>/) #old format to be backwards compatible
          session = session.split("\n")
          new_value = ""
          type = ""
          session.each do |s|
            s.gsub!('"', '\"')
            if s.match?(/^(Me|chatGPT)> /)
              if new_value != ""
                #escape new_value to be able to store it as json
                session_new_format << "{\"role\": \"#{type}\", \"content\": [{\"type\": \"text\", \"text\": #{new_value.to_json}}]}"
                new_value = ""
              end
              if s.match?(/^Me> /)
                type = "user"
              else
                type = "assistant"
              end
              s.gsub!(/^(Me|chatGPT)> /, "")
              #s.gsub!("'", "\\'")
              new_value += s + "\n"
            else
              #s.gsub!("'", "\\'")
              new_value += s + "\n"
            end
          end
          session_new_format << "{\"role\": \"#{type}\", \"content\": [{\"type\": \"text\", \"text\": #{new_value.to_json}}]}"
        end
        if session_new_format.empty?
          #each line is json, so we need to convert it to ruby using json parser
          session = session.split("\n").map{|s| JSON.parse(s, symbolize_names: true)}
        else
          session = []
          session_new_format.each do |s|
            session << JSON.parse(s, symbolize_names: true)
          end
        end
        @ai_gpt[team_id_user][session_name] = session.deep_copy
      end
    end
  end
end
