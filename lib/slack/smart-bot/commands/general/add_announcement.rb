class SlackSmartBot

  def add_announcement(user, type, message)
    save_stats(__method__)
    if config[:allow_access].key?(__method__) and !config[:allow_access][__method__].include?(user.name) and !config[:allow_access][__method__].include?(user.id) and 
      (!user.key?(:enterprise_user) or ( user.key?(:enterprise_user) and !config[:allow_access][__method__].include?(user[:enterprise_user].id)))
      respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
    else
      if File.exists?("#{config.path}/announcements/#{Thread.current[:dest]}.csv") and !@announcements.key?(Thread.current[:dest])
        t = CSV.table("#{config.path}/announcements/#{Thread.current[:dest]}.csv", headers: ['message_id', 'user_deleted', 'user_created', 'date', 'time', 'type', 'message'])
        @announcements[Thread.current[:dest]] = t
        num = t[:message_id].max + 1
      elsif !@announcements.key?(Thread.current[:dest])
        File.open("#{config.path}/announcements/#{Thread.current[:dest]}.csv","w")
        t = CSV.table("#{config.path}/announcements/#{Thread.current[:dest]}.csv", headers: ['message_id', 'user_deleted', 'user_created', 'date', 'time', 'type', 'message'])
        num = 1
        @announcements[Thread.current[:dest]] = t
      else
        num = @announcements[Thread.current[:dest]][:message_id].max + 1
      end
      values = [num, '', user.name, Time.now.strftime("%Y/%m/%d"), Time.now.strftime("%H:%M"), type, message]
      @announcements[Thread.current[:dest]] << values
      CSV.open("#{config.path}/announcements/#{Thread.current[:dest]}.csv", "a+") do |csv|
        csv << values
      end
      respond 'The announcement has been added. Related commands `see announcements`, `delete announcement ID`'

    end
  end
end
