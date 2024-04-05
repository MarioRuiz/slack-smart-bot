class SlackSmartBot

  def delete_announcement(user, message_id)
    save_stats(__method__)
    if has_access?(__method__, user)
      if Thread.current[:typem] == :on_call
        channel = Thread.current[:dchannel]
      else
        channel = Thread.current[:dest]
      end
      if File.exist?("#{config.path}/announcements/#{channel}.csv") and !@announcements.key?(channel)
        t = CSV.table("#{config.path}/announcements/#{channel}.csv", headers: ['message_id', 'user_team_id_deleted', 'user_deleted', 'user_team_id_created', 'user_created', 'date', 'time', 'type', 'message'])
        @announcements[channel] = t
      end
      found = false
      message = ''
      if @announcements.key?(channel) and @announcements[channel][:message_id].include?(message_id.to_i)
        CSV.open("#{config.path}/announcements/#{channel}.csv", "w") do |csv|
          @announcements[channel].each do |row|
            if row[:message_id].to_i == message_id.to_i
              message = row[:message]
              row[:user_team_id_deleted] = user.team_id
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
