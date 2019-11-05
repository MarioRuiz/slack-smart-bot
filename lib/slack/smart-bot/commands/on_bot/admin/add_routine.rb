class SlackSmartBot
  # helpadmin: ----------------------------------------------
  # helpadmin: `add routine NAME every NUMBER PERIOD COMMAND`
  # helpadmin: `add routine NAME every NUMBER PERIOD`
  # helpadmin: `add silent routine NAME every NUMBER PERIOD`
  # helpadmin: `create routine NAME every NUMBER PERIOD`
  # helpadmin: `add routine NAME at TIME COMMAND`
  # helpadmin: `add routine NAME at TIME`
  # helpadmin: `add silent routine NAME at TIME`
  # helpadmin: `create routine NAME at TIME`
  # helpadmin:    It will execute the command/rule supplied. Only for Admin and Master Admins.
  # helpadmin:    If no COMMAND supplied, then it will be necessary to attach a file with the code to be run and add this command as message to the file. ONLY for MASTER ADMINS.
  # helpadmin:    In case *silent* provided then when executed will be only displayed if the routine returns a message
  # helpadmin:    NAME: one word to identify the routine
  # helpadmin:    NUMBER: Integer
  # helpadmin:    PERIOD: days, d, hours, h, minutes, mins, min, m, seconds, secs, sec, s
  # helpadmin:    TIME: time at format HH:MM:SS
  # helpadmin:    COMMAND: any valid smart bot command or rule
  # helpadmin:    Examples:
  # helpadmin:      _add routine example every 30s ruby puts 'a'_
  # helpadmin:      _add routine example every 3 days ruby puts 'a'_
  # helpadmin:      _add routine example at 17:05 ruby puts 'a'_
  # helpadmin:      _create silent routine every 12 hours !Run customer tests_
  # helpadmin:
  def add_routine(dest, from, user, name, type, number_time, period, command_to_run, files, silent)
    if files.nil? or files.size == 0 or (files.size > 0 and config.masters.include?(from))
      if config.admins.include?(from)
        if @routines.key?(@channel_id) && @routines[@channel_id].key?(name)
          respond "I'm sorry but there is already a routine with that name.\nCall `see routines` to see added routines", dest
        else
          number_time += ":00" if number_time.split(":").size == 2
          if (type == "at") && !number_time.match?(/^[01][0-9]:[0-5][0-9]:[0-5][0-9]$/) &&
             !number_time.match?(/^2[0-3]:[0-5][0-9]:[0-5][0-9]$/)
            respond "Wrong time specified: *#{number_time}*"
          else
            file_path = ""
            every = ""
            at = ""
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
              at = number_time
              if next_run.strftime("%H:%M:%S") < number_time
                nt = number_time.split(":")
                next_run = Time.new(next_run.year, next_run.month, next_run.day, nt[0], nt[1], nt[2])
              else
                next_run += (24 * 60 * 60) # one more day
                nt = number_time.split(":")
                next_run = Time.new(next_run.year, next_run.month, next_run.day, nt[0], nt[1], nt[2])
              end
              every_in_seconds = 24 * 60 * 60
            end
            Dir.mkdir("#{config.path}/routines/#{@channel_id}") unless Dir.exist?("#{config.path}/routines/#{@channel_id}")

            if !files.nil? && (files.size == 1)
              @logger.info files[0].inspect if config.testing
              file_path = "#{config.path}/routines/#{@channel_id}/#{name}#{files[0].name.scan(/[^\.]+(\.\w+$)/).join}"
              http = NiceHttp.new(host: "https://files.slack.com", headers: { "Authorization" => "Bearer #{config[:token]}" }, log_headers: :partial)
              http.get(files[0].url_private_download, save_data: file_path)
              system("chmod +x #{file_path}")
            end

            @routines[@channel_id] = {} unless @routines.key?(@channel_id)
            @routines[@channel_id][name] = { channel_name: config.channel, creator: from, creator_id: user.id, status: :on,
                                             every: every, every_in_seconds: every_in_seconds, at: at, file_path: file_path, 
                                             command: command_to_run.to_s.strip, silent: silent,
                                             next_run: next_run.to_s, dest: dest, last_run: "", last_elapsed: "", 
                                             running: false }
            update_routines
            respond "Added routine *`#{name}`* to the channel", dest
            create_routine_thread(name)
          end
        end
      else
        respond "Only admin users can use this command", dest
      end
    else
      respond "Only master admin users can add files to routines", dest
    end
  end
end
