class SlackSmartBot

  def get_users()
    begin
      users = []
      cursor = nil
      if config.simulate
        users = client.web_client.users_list
      else
        begin
            resp = client.web_client.users_list(limit: 1000, cursor: cursor)
            if resp.key?(:members) and  resp[:members].is_a?(Array) and resp[:members].size > 0
                users << resp[:members]
            end
            cursor = resp.get_values(:next_cursor).values[-1]
        end until cursor.empty?
        users.flatten!
      end
      users.each do |user|
        # in case of Enterprise Grid we use the enterprise_id as team_id and the enterprise_user id as user_id
        if user.key?(:enterprise_user) and user[:enterprise_user].key?(:enterprise_id)
          user[:team_id] = user[:enterprise_user][:enterprise_id]
          user[:id] = user[:enterprise_user][:id]
        end
      end
      return users
    rescue Exception => stack
      @logger.warn stack
    end
  end
end
