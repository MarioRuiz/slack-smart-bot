class SlackSmartBot

  def add_announcement(user, type, message)
    save_stats(__method__)
    if has_access?(__method__, user)
      if Thread.current[:typem] == :on_call
        channel = Thread.current[:dchannel]
      else
        channel = Thread.current[:dest]
      end
      if File.exists?("#{config.path}/announcements/#{channel}.csv") and !@announcements.key?(channel)
        t = CSV.table("#{config.path}/announcements/#{channel}.csv", headers: ['message_id', 'user_deleted', 'user_created', 'date', 'time', 'type', 'message'])
        @announcements[channel] = t
        num = t[:message_id].max + 1
      elsif !@announcements.key?(channel)
        File.open("#{config.path}/announcements/#{channel}.csv","w")
        t = CSV.table("#{config.path}/announcements/#{channel}.csv", headers: ['message_id', 'user_deleted', 'user_created', 'date', 'time', 'type', 'message'])
        num = 1
        @announcements[channel] = t
      else
        num = @announcements[channel][:message_id].max + 1
      end
      values = [num, '', user.name, Time.now.strftime("%Y/%m/%d"), Time.now.strftime("%H:%M"), type, message]
      @announcements[channel] << values
      CSV.open("#{config.path}/announcements/#{channel}.csv", "a+") do |csv|
        csv << values
      end
      respond "The announcement has been added. (id: #{num}).\nRelated commands `see announcements`, `delete announcement ID`"

    end
  end
end
