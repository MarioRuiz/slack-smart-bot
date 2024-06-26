class SlackSmartBot
  # helpadmin: ----------------------------------------------
  # helpadmin: >*<https://github.com/MarioRuiz/slack-smart-bot#routines|ROUTINES>*
  # helpadmin: `add routine NAME every NUMBER PERIOD COMMAND`
  # helpadmin: `add routine NAME every NUMBER PERIOD #CHANNEL COMMAND`
  # helpadmin: `add routine NAME every NUMBER PERIOD`
  # helpadmin: `add bgroutine NAME every NUMBER PERIOD`
  # helpadmin: `add silent routine NAME every NUMBER PERIOD`
  # helpadmin: `add silent bgroutine NAME every NUMBER PERIOD`
  # helpadmin: `create routine NAME every NUMBER PERIOD`
  # helpadmin: `add routine NAME at TIME COMMAND`
  # helpadmin: `add routine NAME at TIME #CHANNEL COMMAND`
  # helpadmin: `add routine NAME on DAYWEEK at TIME COMMAND`
  # helpadmin: `add routine NAME on DAYWEEK at TIME #CHANNEL COMMAND`
  # helpadmin: `add routine NAME on the DAY_OF_MONTH at TIME COMMAND`
  # helpadmin: `add routine NAME at TIME`
  # helpadmin: `add silent routine NAME at TIME`
  # helpadmin: `create routine NAME at TIME`
  # helpadmin:    It will execute the command/rule supplied. Only for Admin and Master Admins.
  # helpadmin:    If no COMMAND supplied, then it will be necessary to attach a file with the code to be run and add this command as message to the file. ONLY for MASTER ADMINS.
  # helpadmin:    In case *bgroutine* then the results of the run won't be published. To see the results call: `see result routine NAME`
  # helpadmin:    In case *silent* provided then when executed will be only displayed if the routine returns a message
  # helpadmin:    NAME: one word to identify the routine
  # helpadmin:    NUMBER: Integer
  # helpadmin:    PERIOD: days, d, hours, h, minutes, mins, min, m, seconds, secs, sec, s
  # helpadmin:    TIME: time at format HH:MM:SS
  # helpadmin:    DAYWEEK: Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday. And their plurals. Also possible to be used 'weekdays' and 'weekends'
  # helpadmin:    #CHANNEL: the destination channel where the results will be published. If not supplied then the bot channel by default or a DM if the command is run from a DM.
  # helpadmin:    COMMAND: any valid smart bot command or rule
  # helpadmin:    It is possible to add a script directly. Only master admins can do it.
  # helpadmin:    Examples:
  # helpadmin:      _add routine example every 30s !ruby puts 'a'_
  # helpadmin:      _add bgroutine example every 3 days !ruby puts 'a'_
  # helpadmin:      _add routine example at 17:05 !ruby puts 'a'_
  # helpadmin:      _create silent routine Example every 12 hours !Run customer tests_
  # helpadmin:      _add bgroutine example on Mondays at 05:00 !run customer tests_
  # helpadmin:      _add routine example on Tuesdays at 09:00 #SREChannel !run db cleanup_
  # helpadmin:      _add routine example on weekdays at 22:00 suggest command_
  # helpadmin:      _add routine example on the 5th at 22:00 suggest command_
  # helpadmin:    <https://github.com/MarioRuiz/slack-smart-bot#routines|more info>
  # helpadmin: command_id: :add_routine
  # helpadmin:
  def add_routine(dest, from, user, name, type, number_time, period, command_to_run, files, silent, channel, routine_type)
    save_stats(__method__)
    if files.nil? or files.size == 0 or (files.size > 0 and config.team_id_masters.include?("#{user.team_id}_#{user.name}"))
      if is_admin?
        if @routines.key?(@channel_id) && @routines[@channel_id].key?(name)
          respond "I'm sorry but there is already a routine with that name.\nCall `see routines` to see added routines", dest
        else
          react :running
          number_time += ":00" if number_time.split(":").size == 2
          if (type != "every") && !number_time.match?(/^[01][0-9]:[0-5][0-9]:[0-5][0-9]$/) &&
             !number_time.match?(/^2[0-3]:[0-5][0-9]:[0-5][0-9]$/)
            respond "Wrong time specified: *#{number_time}*"
          else
            file_path = ""
            every = ""
            at = ""
            dayweek = ''
            daymonth = ''
            next_run = Time.now
            case period.downcase
            when "days", "d"
              every = "#{number_time} days"
              every_in_seconds = number_time.to_i * 24 * 60 * 60
            when "hours", "h"
              every = "#{number_time} hours"
              every_in_seconds = number_time.to_i * 60 * 60
            when "minutes", "mins", "min", "m"
              every = "#{number_time} minutes"
              every_in_seconds = number_time.to_i * 60
            when "seconds", "secs", "sec", "s"
              every = "#{number_time} seconds"
              every_in_seconds = number_time.to_i
            else # time
              if type != 'at' and type.match?(/^\d+$/) # day of month
                day = type.to_i
                daymonth = type
                if day > 31
                  respond "Wrong day of month specified: *#{day}*", dest
                  return
                end
                if Date.today.day > day
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
                every_in_seconds = days * 24 * 60 * 60 # one day

              elsif type != 'at' and type!='weekday' and type!='weekend'
                dayweek = type.downcase

                days = ['sunday','monday','tuesday','wednesday','thursday','friday','saturday']
                incr = days.index(dayweek) - Time.now.wday
                if incr < 0
                  incr = (7+incr)*24*60*60
                else
                  incr = incr * 24 * 60 * 60
                end
                days = incr/(24*60*60)
                every_in_seconds = 7 * 24 * 60 * 60 # one week
              elsif type=='weekend'
                dayweek = type.downcase
                days = 0
                every_in_seconds = 24 * 60 * 60 # one day
              elsif type=='weekday'
                dayweek = type.downcase
                days = 0
                every_in_seconds = 24 * 60 * 60 # one day
              else
                days = 0
                every_in_seconds = 24 * 60 * 60 # one day
              end

              at = number_time
              if next_run.strftime("%H:%M:%S") < number_time and days == 0
                nt = number_time.split(":")
                next_run = Time.new(next_run.year, next_run.month, next_run.day, nt[0], nt[1], nt[2])
              else
                next_run += ((24 * 60 * 60) * days) # one or more days
                nt = number_time.split(":")
                next_run = Time.new(next_run.year, next_run.month, next_run.day, nt[0], nt[1], nt[2])
              end
            end
            Dir.mkdir("#{config.path}/routines/#{@channel_id}") unless Dir.exist?("#{config.path}/routines/#{@channel_id}")

            if !files.nil? && (files.size == 1)
              @logger.info files[0].inspect if config.testing
              file_path = "#{config.path}/routines/#{@channel_id}/#{name}#{files[0].name.scan(/[^\.]+(\.\w+$)/).join}"
              if files[0].filetype == "ruby" and files[0].name.scan(/[^\.]+(\.\w+$)/).join == ''
                file_path += ".rb"
              end
              if files[0].key?(:content)
                File.open(file_path, 'w') do |f|
                  f.write files[0].content
                end
              else
                http = NiceHttp.new(host: "https://files.slack.com", headers: { "Authorization" => "Bearer #{config[:token]}" }, log_headers: :partial)
                http.get(files[0].url_private_download, save_data: file_path)
              end
              system("chmod +x #{file_path}")
            end
            get_channels_name_and_id() unless @channels_name.keys.include?(channel) or @channels_id.keys.include?(channel)
            channel_id = nil
            if @channels_name.key?(channel) #it is an id
              channel_id = channel
              channel = @channels_name[channel_id]
            elsif @channels_id.key?(channel) #it is a channel name
              channel_id = @channels_id[channel]
            end

            channel_id = dest if channel_id.to_s == ''
            @routines[@channel_id] = {} unless @routines.key?(@channel_id)
            @routines[@channel_id][name] = { channel_name: config.channel, creator_team_id: user.team_id, creator: from, creator_id: user.id, status: :on,
                                             every: every, every_in_seconds: every_in_seconds, at: at, dayweek: dayweek, daymonth: daymonth, file_path: file_path,
                                             command: command_to_run.to_s.strip, silent: silent,
                                             next_run: next_run.to_s, dest: channel_id, last_run: "", last_elapsed: "",
                                             running: false, routine_type: routine_type}
            update_routines()
            respond "Added routine *`#{name}`* to the channel", dest
            create_routine_thread(name, @routines[@channel_id][name])
          end
          unreact :running
        end
      else
        respond "Only admin users can use this command", dest
      end
    else
      respond "Only master admin users can add files to routines", dest
    end
  end
end
