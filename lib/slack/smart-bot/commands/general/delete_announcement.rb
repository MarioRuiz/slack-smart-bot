class SlackSmartBot

  def delete_announcement(user, message_id)
    save_stats(__method__)
    if config[:allow_access].key?(__method__) and !config[:allow_access][__method__].include?(user.name) and !config[:allow_access][__method__].include?(user.id) and 
      (!user.key?(:enterprise_user) or ( user.key?(:enterprise_user) and !config[:allow_access][__method__].include?(user[:enterprise_user].id)))
      respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
    else
      if File.exists?("#{config.path}/announcements/#{Thread.current[:dest]}.csv") and !@announcements.key?(Thread.current[:dest])
        t = CSV.table("#{config.path}/announcements/#{Thread.current[:dest]}.csv", headers: ['message_id', 'user_deleted', 'user_created', 'date', 'time', 'type', 'message'])
        @announcements[Thread.current[:dest]] = t
      end
      found = false
      message = ''
      if @announcements[Thread.current[:dest]][:message_id].include?(message_id.to_i)
        CSV.open("#{config.path}/announcements/#{Thread.current[:dest]}.csv", "w") do |csv|
          @announcements[Thread.current[:dest]].each do |row|
            if row[:message_id].to_i == message_id.to_i
              message = row[:message]
              row[:user_deleted] = user.name
            end    
            csv << row
          end
        end
        respond "The announcement has been deleted: #{message}"
      else
        respond "Sorry but I didn't find the message id #{message_id}. Call `see announcements` to see the ids."
      end

    end
  end
end
