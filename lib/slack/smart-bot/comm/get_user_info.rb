class SlackSmartBot

  def get_user_info(user, is_bot: false)
    begin
      if user.to_s.length>0
        if user[0]=='@' #name
          user = user[1..-1]
          is_name = true
        else
          is_name = false
        end
        if user.match?(/^[A-Z0-9]{7,11}_/) #team_id_user_name
          team_id = user.split('_')[0]
          user = user.split('_')[1..-1].join('_')
        else
          team_id = config.team_id
        end
        if config.simulate and config.key?(:client) #todo: add support for bots
          if client.web_client.users_info.key?(user.to_sym) #id
            client.web_client.users_info[user.to_sym]
          else #name
            client.web_client.users_info.select{|k, v| v[:user][:name] == user and v[:user][:team_id] == team_id}.values[-1]
          end
        else
          if is_bot
            @logger.info "Getting bot info for <#{user}>"
            begin
              result = client.web_client.bots_info(bot: user)
            rescue Exception => stack
              @logger.warn stack
              return nil
            end
            if !result.nil? and result.key?(:bot) and result[:bot].key?(:user_id)
                user = result[:bot][:user_id]
                is_name = false
            else
              return nil
            end
          end
          #todo: see how to get user info using also the team_id
          if is_name
            result = client.web_client.users_info(user: "@#{user}")
          else
            result = client.web_client.users_info(user: user)
          end
          # in case of Enterprise Grid we use the enterprise_id as team_id and the enterprise_user id as user_id
          if !result.nil? and result.key?(:user) and result[:user].key?(:enterprise_user) and result[:user][:enterprise_user].key?(:enterprise_id)
            result[:user][:team_id] = result[:user][:enterprise_user][:enterprise_id]
            result[:user][:id] = result[:user][:enterprise_user][:id]
          end

          return result
        end
      end
    rescue Exception => stack
      @logger.warn stack
    end
  end
end
