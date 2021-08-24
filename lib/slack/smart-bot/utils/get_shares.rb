class SlackSmartBot

  def get_shares()
    channel = @channels_name[@channel_id]
    if File.exist?("#{config.path}/shares/#{channel}.csv")
      "#{config.path}/shares/#{channel}.csv"
      t = CSV.table("#{config.path}/shares/#{channel}.csv", headers: ['share_id', 'user_deleted', 'user_created', 'date', 'time', 'type', 'to_channel', 'condition'])
      t.delete_if {|row| row[:user_deleted] != ''}
      @shares[channel] = t
    end
  end
end
