class SlackSmartBot

  def get_user_info(user)
    if user.to_s.length>0
      if config.simulate and config.key?(:client)
        if user[0]=='@' #name
          client.web_client.users_info.select{|k, v| v[:user][:name] == user[1..-1]}.values[-1]
        else #id
          client.web_client.users_info[user.to_sym]
        end
      else
        client.web_client.users_info(user: user)
      end
    end
  end
end
