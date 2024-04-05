class SlackSmartBot

  def delete_share(user, share_id)
    save_stats(__method__)
    if has_access?(__method__, user)
      if Thread.current[:typem] == :on_call
        channel = Thread.current[:dchannel]
      else
        channel = Thread.current[:dest]
      end
      if File.exist?("#{config.path}/shares/#{@channels_name[channel]}.csv") and !@shares.key?(@channels_name[channel])
        t = CSV.table("#{config.path}/shares/#{@channels_name[channel]}.csv", headers: ['share_id', 'user_team_id_deleted', 'user_deleted', 'user_team_id_created', 'user_created', 'date', 'time', 'type', 'to_channel', 'condition'])
        @shares[@channels_name[channel]] = t
      end
      found = false
      message = ''
      if @shares[@channels_name[channel]][:share_id].include?(share_id.to_i)
        CSV.open("#{config.path}/shares/#{@channels_name[channel]}.csv", "w") do |csv|
          @shares[@channels_name[channel]].each do |row|
            if row[:share_id].to_i == share_id.to_i
              message = row[:condition]
              row[:user_team_id_deleted] = user.team_id
              row[:user_deleted] = user.name
            end    
            csv << row
          end
        end
        respond "The share has been deleted: #{message}"
      else
        respond "Sorry but I didn't find the share id #{share_id}. Call `see shares` to see all the ids."
      end

    end
  end
end
