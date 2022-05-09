class SlackSmartBot

  def get_presence(user)
    begin
      if user.to_s.length>0
        if config.simulate and config.key?(:client)
          if user[0]=='@' #name
            client.web_client.users_get_presence.select{|k, v| v[:name] == user[1..-1]}.values[-1]
          else #id
            client.web_client.users_get_presence[user.to_sym]
          end
        else
          client.web_client.users_getPresence(user: user)
        end
      end
    rescue Exception => stack
      @logger.warn stack
    end
  end
end
