class SlackSmartBot
  def find_user(user, get_sso_user_name: false)
    @users = get_users() if @users.empty?
    userh = { id: "", name: "" }
    user_info = nil
    if user.to_s.length > 0 and user != "@"
      if user[0] == "@" #name
        user = user[1..-1]
        is_name = true
      else
        is_name = false
      end
      if user.match?(/^[A-Z0-9]{7,11}_/) #team_id_user_name
        team_id = user.split("_")[0]
        user = user.split("_")[1..-1].join("_")
        is_name = true
      else
        team_id = config.team_id
        is_name = false
      end

      if is_name
        userh[:name] = user
      elsif user.match?(/[a-z]/)
        # if not is name and user contains any downcase letter, then we guess it is a name
        userh[:name] = user
      else
        userh[:id] = user
      end
      user_info = @users.select { |u|
        # for user id we don't check team_id as for the moment according to Slack API, user id is unique
        ((userh[:id].to_s != "" and u.id == userh[:id]) or (u.key?(:enterprise_user) and u.enterprise_user.id == userh[:id])) or
        ((userh[:name].to_s != "" and u.name == userh[:name] and u.team_id == team_id) or (u.key?(:enterprise_user) and u.enterprise_user.name == userh[:name] and u.enterprise_user.enterprise_id == team_id))
      }[-1]

      if user_info.nil? #other workspace
        user_info = get_user_info(user)
        unless user_info.nil? or user_info.empty?
          @users << user_info.user
          user_info = @users.select { |u|
            # for user id we don't check team_id as for the moment according to Slack API, user id is unique
            ((userh[:id].to_s != "" and u.id == userh[:id]) or (u.key?(:enterprise_user) and u.enterprise_user.id == userh[:id])) or
            ((userh[:name].to_s != "" and u.name == userh[:name] and u.team_id == team_id) or (u.key?(:enterprise_user) and u.enterprise_user.name == userh[:name] and u.enterprise_user.enterprise_id == team_id))
          }[-1]
        end
      end
    end
    if get_sso_user_name and defined?(@ldap) and !@ldap.nil? and !user_info.nil? and user_info[:sso_user_name].to_s.empty? and !user_info[:profile].email.to_s.empty?
      begin
        if @ldap.bind
          email = user_info[:profile].email
          filter1 = Net::LDAP::Filter.eq("mail", email)
          filter2 = Net::LDAP::Filter.eq("mailAlternateAddress", email)
          filter3 = Net::LDAP::Filter.eq("mail", email.gsub(/@.+$/, ""))
          filter4 = Net::LDAP::Filter.eq("mailAlternateAddress", email.gsub(/@.+$/, ""))
          filter = filter1 | filter2 | filter3 | filter4
          @ldap.search(:base => config.ldap.treebase, :filter => filter) do |entry|
            user_info[:sso_user_name] = entry.uid[0]
          end
        end
      rescue => exception
        if defined?(@logger)
          @logger.fatal exception
        else
          puts exception
        end
      end
    end
    return user_info
  end
end
