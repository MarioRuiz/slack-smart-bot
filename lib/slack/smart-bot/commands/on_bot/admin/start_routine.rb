class SlackSmartBot

  # helpadmin: ----------------------------------------------
  # helpadmin: `start routine NAME`
  # helpadmin:    It will start a paused routine
  # helpadmin:    You can use this command only if you are an admin user
  # helpadmin:    NAME: one word to identify the routine
  # helpadmin:    Examples:
  # helpadmin:      _start routine example_
  # helpadmin:    <https://github.com/MarioRuiz/slack-smart-bot#routines|more info>
  # helpadmin: command_id: :start_routine
  # helpadmin:

  def start_routine(dest, from, name)
    save_stats(__method__)
    if is_admin?
      if !config.on_master_bot and dest[0] == "D"
        respond "It's only possible to start routines from MASTER channel from a direct message with the bot.", dest
      elsif @routines.key?(@channel_id) and @routines[@channel_id].key?(name)
        @routines[@channel_id][name][:status] = :on
        if @routines[@channel_id][name].key?(:daymonth) and @routines[@channel_id][name][:daymonth] != ''
          started = Time.now
          daymonth = @routines[@channel_id][name][:daymonth]
          day = daymonth.to_i
          nt = @routines[@channel_id][name][:at].split(":")
          if Time.now > Time.new(Time.now.year, Time.now.month, day, nt[0], nt[1], nt[2])
              next_month = Date.new(Date.today.year, Date.today.month, 1) >> 1
          else
              next_month = Date.new(Date.today.year, Date.today.month, 1)
          end
          next_month_last_day = Date.new(next_month.year, next_month.month, -1)
          if day > next_month_last_day.day
              next_time = Date.new(next_month.year, next_month.month, next_month_last_day.day)
          else
              next_time = Date.new(next_month.year, next_month.month, day)
          end
          days = (next_time - Date.today).to_i
          next_run = started + (days * 24 * 60 * 60) # one more day/week
          next_run = Time.new(next_run.year, next_run.month, next_run.day, nt[0], nt[1], nt[2])
          @routines[@channel_id][name][:next_run] = next_run.to_s
          @routines[@channel_id][name][:sleeping] = (next_run - started).ceil
        elsif @routines[@channel_id][name][:at]!=''
          started = Time.now
          if started.strftime("%H:%M:%S") < @routines[@channel_id][name][:at]
            nt = @routines[@channel_id][name][:at].split(":")
            next_run = Time.new(started.year, started.month, started.day, nt[0], nt[1], nt[2])
          else
            next_run = started + (24 * 60 * 60) # one more day
            nt = @routines[@channel_id][name][:at].split(":")
            next_run = Time.new(next_run.year, next_run.month, next_run.day, nt[0], nt[1], nt[2])
          end
          @routines[@channel_id][name][:next_run] = next_run.to_s
          @routines[@channel_id][name][:sleeping] = (next_run - started).ceil
        end
        update_routines()
        respond "The routine *`#{name}`* has been started. The change will take effect in less than 30 secs.", dest
      else
        respond "There isn't a routine with that name: *`#{name}`*.\nCall `see routines` to see added routines", dest
      end
    else
      respond "Only admin users can use this command", dest
    end
  end
end
