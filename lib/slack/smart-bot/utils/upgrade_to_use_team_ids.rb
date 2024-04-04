class SlackSmartBot
  def upgrade_to_use_team_ids()
    team_id = config.team_id

    if Dir.exist?("#{config.path}/rules/") #admins_channels.yaml and access_channels.yaml
      files_updated = []
      Dir.glob(config.path + "/rules/**/*").select { |i| i[/admins_channels.yaml$/] }.each do |f|
        t = YAML.load_file(f)
        n = {}
        t.each do |k, v|
          if v.length > 0
            # do it only if it is not already a team_id: /^[A-Z0-9]{7,11}_/
            # if it matches the pattern, it is already with a team_id
            # if it doesn't match the pattern, it is not with a team_id
            n[k] = []
            v.each do |m|
              if !m.to_s.match?(/^[A-Z0-9]{7,11}_/)
                n[k] << team_id.to_s + "_" + m
                files_updated << f unless files_updated.include?(f)
              else
                n[k] << m
              end
            end
          else
            n[k] = v
          end
        end
        File.open(f, "w") { |f| f.write n.to_yaml } if files_updated.include?(f)
      end
      @logger.info "Updated admins_channels.yaml files to use team ids" unless files_updated.empty?

      files_updated = []
      Dir.glob(config.path + "/rules/**/*").select { |i| i[/access_channels.yaml$/] }.each do |f|
        t = YAML.load_file(f)
        n = {}
        t.each do |k, v|
          n[k] = {}
          v.each do |k2, v2|
            if v2.length > 0
              # do it only if it is not already a team_id: /^[A-Z0-9]{7,11}_/
              # if it matches the pattern, it is already with a team_id
              # if it doesn't match the pattern, it is not with a team_id
              n[k][k2] = []
              v2.each do |m|
                if !m.to_s.match?(/^[A-Z0-9]{7,11}_/)
                  n[k][k2] << team_id.to_s + "_" + m
                  files_updated << f unless files_updated.include?(f)
                else
                  n[k][k2] << m
                end
              end
            else
              n[k][k2] = v2
            end
          end
        end
        File.open(f, "w") { |f| f.write n.to_yaml } if files_updated.include?(f)

      end
      @logger.info "Updated access_channels.yaml files to use team ids" unless files_updated.empty?

      files_updated = []

      Dir.glob(config.path + "/rules/*").select { |i| i[/rules_imported.yaml$/] }.each do |f|
        t = YAML.load_file(f)
        n = {}
        t.each do |k, v|
          if !k.to_s.match?(/^[A-Z0-9]{7,11}_/)
            n["#{team_id.to_s}_#{k}"] = v
            files_updated << f unless files_updated.include?(f)
          else
            n[k] = v
          end
        end
        File.open(f, "w") { |f| f.write n.to_yaml } if files_updated.include?(f)
      end
      @logger.info "Updated rules_imported.yaml files to use team ids" unless files_updated.empty?
    end

    if Dir.exist?("#{config.path}/teams/")
      files_updated = []
      #todo: do it also for deleted memos files
      Dir.entries("#{config.path}/teams/").select { |i| i[/\.yaml$/] }.each do |f|
        t = YAML.load(Utils::Encryption.decrypt(File.read("#{config.path}/teams/#{f}"), config))
        t[:members].each do |k, v|
          n = []
          v.each do |m|
            if !m.to_s.match?(/^[A-Z0-9]{7,11}_/)
              n << team_id.to_s + "_" + m
              files_updated << f unless files_updated.include?(f)
            else
              n << m
            end
          end
          t[:members][k] = n
        end

        # update memos.user and memos.comments.user_name
        if t.key?(:memos)
          t[:memos].each do |m|
            if !m[:user].to_s.match?(/^[A-Z0-9]{7,11}_/)
              m[:user] = team_id.to_s + "_" + m[:user]
              files_updated << f unless files_updated.include?(f)
            end
            if m.key?(:comments)
              m[:comments].each do |c|
                if !c[:user_name].to_s.match?(/^[A-Z0-9]{7,11}_/)
                  c[:user_name] = team_id.to_s + "_" + c[:user_name]
                  files_updated << f unless files_updated.include?(f)
                end
              end
            end
          end
        end

        if !t[:user].to_s.match?(/^[A-Z0-9]{7,11}_/)
          t[:user] = team_id.to_s + "_" + t[:user]
          files_updated << f unless files_updated.include?(f)
        end
        if !t[:creator].to_s.match?(/^[A-Z0-9]{7,11}_/)
          t[:creator] = team_id.to_s + "_" + t[:creator]
          files_updated << f unless files_updated.include?(f)
        end
        if files_updated.include?(f)
          File.open("#{config.path}/teams/#{f}", "w") { |file|
            file.flock(File::LOCK_EX)
            file.write(Utils::Encryption.encrypt(t.to_yaml, config))
            file.flock(File::LOCK_UN)
          }
        end
      end
      @logger.info "Updated teams files to use team ids" unless files_updated.empty?
    end

    #add team_id to the user_name: team_id_user_name, exclude the key :all
    if Dir.exist?("#{config.path}/shortcuts/")
      files_updated = []
      Dir.entries("#{config.path}/shortcuts/").select { |i| i[/\.yaml$/] }.each do |f|
        t = YAML.load_file("#{config.path}/shortcuts/#{f}")
        n = {}
        t.each do |k, v|
          if k != :all and !k.to_s.match?(/^[A-Z0-9]{7,11}_/)
            n[team_id.to_s + "_" + k.to_s] = t[k]
            files_updated << f unless files_updated.include?(f)
          else
            n[k] = t[k]
          end
        end
        File.open("#{config.path}/shortcuts/#{f}", "w") { |f| f.write n.to_yaml } if files_updated.include?(f)
      end
      @logger.info "Updated shortcuts files to use team ids" unless files_updated.empty?
    end

    #repl files are yaml
    if Dir.exist?("#{config.path}/repl/")
      files_updated = []
      Dir.entries("#{config.path}/repl/").select { |i| i[/\.yaml$/] }.each do |f|
        t = YAML.load_file("#{config.path}/repl/#{f}")
        t.each do |k, v|
          if v[:creator_team_id].to_s == ""
            v[:creator_team_id] = team_id
            files_updated << f unless files_updated.include?(f)
          end
        end
        File.open("#{config.path}/repl/#{f}", "w") { |f| f.write t.to_yaml } if files_updated.include?(f)
      end
      @logger.info "Updated repl files to use team ids" unless files_updated.empty?
    end

    if Dir.exist?("#{config.path}/routines/")
      files_updated = []
      Dir.entries("#{config.path}/routines/").select { |i| i[/\.yaml$/] }.each do |f|
        t = YAML.load_file("#{config.path}/routines/#{f}")
        t.each do |k, v|
          v.each do |k2, v2|
            if v2[:creator_team_id].to_s == ""
              v2[:creator_team_id] = team_id
              files_updated << f unless files_updated.include?(f)
            end
          end
        end
        File.open("#{config.path}/routines/#{f}", "w") { |f| f.write t.to_yaml } if files_updated.include?(f)
      end
      @logger.info "Updated routines files to use team ids" unless files_updated.empty?
    end

    #shares files are csv
    if Dir.exist?("#{config.path}/shares/")
      Dir.entries("#{config.path}/shares/").select { |i| i[/\.csv$/] }.each do |f|
        #verify if the file has the team_id already, in that case the number of columns should be 10
        t = CSV.table("#{config.path}/shares/#{f}")
        if t.headers.length == 8
          t = CSV.table("#{config.path}/shares/#{f}", headers: ["share_id", "user_deleted", "user_created", "date", "time", "type", "to_channel", "condition"])
          #save it in this order:
          new_headers = ["share_id", "user_team_id_deleted", "user_deleted", "user_team_id_created", "user_created", "date", "time", "type", "to_channel", "condition"]
          new_t = []
          t.each do |m|
            if m[:user_deleted].to_s == ""
              user_team_id_deleted = ""
            else
              user_team_id_deleted = team_id
            end
            new_t << [m[:share_id], user_team_id_deleted, m[:user_deleted], team_id, m[:user_created], m[:date], m[:time], m[:type], m[:to_channel], m[:condition]]
          end
          CSV.open("#{config.path}/shares/#{f}", "wb") do |csv|
            new_t.each do |row|
              csv << row
            end
          end
          @logger.info "Updated shares to use team ids"
        end
      end
    end

    #announcements
    if Dir.exist?("#{config.path}/announcements/")
      Dir.entries("#{config.path}/announcements/").select { |i| i[/\.csv$/] }.each do |f|
        #verify if the file has the team_id already, in that case the number of columns should be 9
        t = CSV.table("#{config.path}/announcements/#{f}")
        if t.headers.length == 7
          t = CSV.table("#{config.path}/announcements/#{f}", headers: ["message_id", "user_deleted", "user_created", "date", "time", "type", "message"])
          #save it in this order:
          new_headers = ["message_id", "user_team_id_deleted", "user_deleted", "user_team_id_created", "user_created", "date", "time", "type", "message"]
          new_t = []
          t.each do |m|
            if m[:user_deleted].to_s == ""
              user_team_id_deleted = ""
            else
              user_team_id_deleted = team_id
            end
            new_t << [m[:message_id], user_team_id_deleted, m[:user_deleted], team_id, m[:user_created], m[:date], m[:time], m[:type], m[:message]]
          end
          CSV.open("#{config.path}/announcements/#{f}", "wb") do |csv|
            new_t.each do |row|
              csv << row
            end
          end

          @logger.info "Updated announcements to use team ids"
        end
      end
    end

    if Dir.exist?("#{config.path}/vacations/") and !Dir.exist?(config.path + "/vacations/" + team_id.to_s)
      FileUtils.mkdir_p(config.path + "/vacations/" + team_id.to_s)
      files_updated = []
      Dir.glob(config.path + "/vacations/*").select { |i| i[/\.yaml$/] }.each do |f|
        FileUtils.mv(f, config.path + "/vacations/" + team_id.to_s)
        files_updated << f
      end
      @logger.info "Updated vacations to use team ids. All moved to #{config.path}/vacations/#{team_id}/" unless files_updated.empty?
    end

    if Dir.exist?("#{config.path}/openai/") and !Dir.exist?(config.path + "/openai/" + team_id.to_s)
      FileUtils.mkdir_p(config.path + "/openai/" + team_id.to_s)
      files_updated = []
      Dir.glob(config.path + "/openai/*").each do |file_or_dir|
        next if file_or_dir == config.path + "/openai/" + team_id.to_s
        FileUtils.mv(file_or_dir, config.path + "/openai/" + team_id.to_s)
        files_updated << file_or_dir
      end
      @logger.info "Updated openai to use team ids. All moved to #{config.path}/openai/#{team_id}/" unless files_updated.empty?
    end

    if Dir.exist?("#{config.path}/personal_settings/") and !Dir.exist?(config.path + "/personal_settings/" + team_id.to_s)
      FileUtils.mkdir_p(config.path + "/personal_settings/" + team_id.to_s)
      files_updated = []
      Dir.glob(config.path + "/personal_settings/*").each do |file_or_dir|
        next if file_or_dir == config.path + "/personal_settings/" + team_id.to_s
        FileUtils.mv(file_or_dir, config.path + "/personal_settings/" + team_id.to_s)
        files_updated << file_or_dir
      end
      @logger.info "Updated personal_settings to use team ids. All moved to #{config.path}/personal_settings/#{team_id}/" unless files_updated.empty?
    end
  end
end
