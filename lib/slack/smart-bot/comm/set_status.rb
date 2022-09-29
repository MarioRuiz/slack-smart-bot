class SlackSmartBot
    def set_status(user_id, status: nil, message: nil, expiration: nil)
      unless client_user.nil?
        if expiration.is_a?(String) and expiration.match?(/^\d\d\d\d\/\d\d\/\d\d$/)
          expiration = Date.parse(expiration, '%Y/%m/%d').to_time.to_i
        elsif expiration.is_a?(Date)
          expiration = expiration.to_time.to_i
        end
        params = []
        params << "'status_emoji': '#{status}'" unless status.nil?
        params << "'status_text': '#{message}'" unless message.nil?
        params << "'status_expiration':  '#{expiration}'" unless expiration.nil?
        begin
          resp = client_user.users_profile_set(user: user_id, profile: "{ #{params.join(', ')} }")
        rescue Exception => exc
          @logger.fatal exc.inspect
        end
      end
    end
  end
  