class SlackSmartBot

  def get_users()
    begin
      users = []
      cursor = nil
      begin
          resp = client.web_client.users_list(limit: 1000, cursor: cursor)
          if resp.key?(:members) and  resp[:members].is_a(Array) and resp[:members].size > 0
              users << resp[:members]
          end
          cursor = resp.get_values(:next_cursor).values[-1]
      end until cursor.empty?
      users.flatten!
      return users
    rescue Exception => stack
      @logger.warn stack
    end
  end
end
