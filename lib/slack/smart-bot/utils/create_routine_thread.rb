class SlackSmartBot

  def create_routine_thread(name, hroutine)
    t = Thread.new do
      while @routines.key?(@channel_id) and @routines[@channel_id].key?(name) and @status != :exit
        @routines[@channel_id][name][:thread] = Thread.current
        started = Time.now
        if @status == :on and @routines[@channel_id][name][:status] == :on
          if !@routines[@channel_id][name].key?(:creator_id) or @routines[@channel_id][name][:creator_id].to_s == ''
            user_info = @users.select{|u| u.name == @routines[@channel_id][name][:creator]}[-1]
            @routines[@channel_id][name][:creator_id] = user_info.id unless user_info.nil? or user_info.empty?
          end
          @logger.info "Routine #{name}: #{@routines[@channel_id][name].inspect}"
          if @routines[@channel_id][name][:file_path].match?(/\.rb$/i)
            ruby = "ruby "
          else
            ruby = ""
          end
          @routines[@channel_id][name][:silent] = false if !@routines[@channel_id][name].key?(:silent)
          if @routines[@channel_id][name][:at] == "" or
             (@routines[@channel_id][name][:at] != "" and @routines[@channel_id][name][:running] and
              @routines[@channel_id][name][:next_run] != "" and Time.now.to_s >= @routines[@channel_id][name][:next_run])
              
            if !@routines[@channel_id][name].key?(:dayweek) or 
              (@routines[@channel_id][name].key?(:dayweek) and @routines[@channel_id][name][:dayweek].to_s!='weekday' and @routines[@channel_id][name][:dayweek].to_s!='weekend') or
              (@routines[@channel_id][name].key?(:dayweek) and @routines[@channel_id][name][:dayweek].to_s=='weekday' and Date.today.wday>=1 and Date.today.wday<=5) or
              (@routines[@channel_id][name].key?(:dayweek) and @routines[@channel_id][name][:dayweek].to_s=='weekend' and (Date.today.wday==6 or Date.today.wday==0)) 
              File.delete "#{config.path}/routines/#{@channel_id}/#{name}_output.txt" if File.exist?("#{config.path}/routines/#{@channel_id}/#{name}_output.txt")
              if @routines[@channel_id][name][:file_path] != ""
                process_to_run = "#{ruby}#{Dir.pwd}#{@routines[@channel_id][name][:file_path][1..-1]}"
                process_to_run = ("cd #{project_folder} &&" + process_to_run) if defined?(project_folder)
                data = {
                  dest: @routines[@channel_id][name][:dest],
                  typem: 'routine_file',
                  user: {id: @routines[@channel_id][name][:creator_id], name: @routines[@channel_id][name][:creator]},
                  files: false,
                  command: @routines[@channel_id][name][:file_path],
                  routine: true,
                  routine_name: name,
                  routine_type: hroutine[:routine_type]
                }
                save_stats(name, data: data)
                stdout, stderr, status = Open3.capture3(process_to_run)
                if !@routines[@channel_id][name][:silent]
                  unless config.on_maintenance
                    if @routines[@channel_id][name][:dest]!=@channel_id
                      respond "routine from <##{@channel_id}> *`#{name}`*: #{@routines[@channel_id][name][:file_path]}", @routines[@channel_id][name][:dest]
                    else
                      respond "routine *`#{name}`*: #{@routines[@channel_id][name][:file_path]}", @routines[@channel_id][name][:dest]
                    end
                  end
                end
                if hroutine[:routine_type].to_s!='bgroutine'
                  if stderr == ""
                    unless stdout.match?(/\A\s*\z/)
                      respond stdout, @routines[@channel_id][name][:dest]
                    end
                  else
                    respond "#{stdout} #{stderr}", @routines[@channel_id][name][:dest]
                  end
                else
                  File.write("#{config.path}/routines/#{@channel_id}/#{name}_output.txt", stdout.to_s+stderr.to_s, mode: "a+")
                end
              else #command
                message = nil
                if !@routines[@channel_id][name][:silent] and !config.on_maintenance
                  if @routines[@channel_id][name][:dest]!=@channel_id
                    message = respond "routine from <##{@channel_id}> *`#{name}`*: #{@routines[@channel_id][name][:command]}", @routines[@channel_id][name][:dest], return_message: true
                  else
                    message = respond "routine *`#{name}`*: #{@routines[@channel_id][name][:command]}", @routines[@channel_id][name][:dest], return_message: true
                  end
                end
                started = Time.now
                data = { channel: @channel_id,
                  dest: @routines[@channel_id][name][:dest],
                  user: @routines[@channel_id][name][:creator_id],
                  text: @routines[@channel_id][name][:command],
                  files: nil,
                  routine: true,
                  routine_name: name,
                  routine_type: hroutine[:routine_type] }
                if !message.nil? and (@routines[@channel_id][name][:command].match?(/^!!/) or @routines[@channel_id][name][:command].match?(/^\^/))
                  data[:ts] = message.ts
                end
                treat_message(data)
              end
              # in case the routine was deleted while running the process
              if !@routines.key?(@channel_id) or !@routines[@channel_id].key?(name)
                Thread.exit
              end
              @routines[@channel_id][name][:last_run] = started.to_s
            elsif (@routines[@channel_id][name].key?(:dayweek) and @routines[@channel_id][name][:dayweek].to_s=='weekday' and (Date.today.wday==6 or Date.today.wday==0)) or
              (@routines[@channel_id][name].key?(:dayweek) and @routines[@channel_id][name][:dayweek].to_s=='weekend' and Date.today.wday>=1 and Date.today.wday<=5) 
              @routines[@channel_id][name][:last_run] = started.to_s
            end
          end
          if @routines[@channel_id][name][:last_run] == "" and @routines[@channel_id][name][:next_run] != "" #for the first create_routine of one routine with at
            elapsed = 0
            require "time"
            every_in_seconds = Time.parse(@routines[@channel_id][name][:next_run]) - Time.now
          elsif @routines[@channel_id][name][:at] != "" #coming from start after pause for 'at'
            if @routines[@channel_id][name].key?(:daymonth) and @routines[@channel_id][name][:daymonth].to_s!='' # day of month
              weekly = false
              daymonth = @routines[@channel_id][name][:daymonth]
              day = daymonth.to_i
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
              every_in_seconds = Time.parse(@routines[@channel_id][name][:next_run]) - Time.now
            elsif @routines[@channel_id][name].key?(:dayweek) and @routines[@channel_id][name][:dayweek].to_s!='' and 
              @routines[@channel_id][name][:dayweek].to_s!='weekend' and @routines[@channel_id][name][:dayweek].to_s!='weekday'
              
              day = @routines[@channel_id][name][:dayweek]
              days = ['sunday','monday','tuesday','wednesday','thursday','friday','saturday']
              incr = days.index(day) - Time.now.wday
              if incr < 0 
                incr = (7+incr)*24*60*60
              else
                incr = incr * 24 * 60 * 60
              end
              days = incr/(24*60*60)
              weekly = true
            elsif @routines[@channel_id][name].key?(:dayweek) and @routines[@channel_id][name][:dayweek].to_s!='' and 
              @routines[@channel_id][name][:dayweek].to_s=='weekend'
              
              weekly = false
              days = 0
            elsif @routines[@channel_id][name].key?(:dayweek) and @routines[@channel_id][name][:dayweek].to_s!='' and 
              @routines[@channel_id][name][:dayweek].to_s=='weekday'
              
              weekly = false
              days = 0
            else
              days = 0
              weekly = false
            end

            if started.strftime("%H:%M:%S") < @routines[@channel_id][name][:at] and days == 0
              nt = @routines[@channel_id][name][:at].split(":")
              next_run = Time.new(started.year, started.month, started.day, nt[0], nt[1], nt[2])
            else 
              if days == 0 and started.strftime("%H:%M:%S") >= @routines[@channel_id][name][:at]
                if weekly
                    days = 7
                elsif @routines[@channel_id][name].key?(:daymonth) and @routines[@channel_id][name][:daymonth].to_s!=''
                  daymonth = @routines[@channel_id][name][:daymonth]
                  day = daymonth.to_i
                  if Date.today.day >= day
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
                else
                    days = 1
                end
              end
              next_run = started + (days * 24 * 60 * 60) # one more day/week
              nt = @routines[@channel_id][name][:at].split(":")
              next_run = Time.new(next_run.year, next_run.month, next_run.day, nt[0], nt[1], nt[2])
            end
            @routines[@channel_id][name][:next_run] = next_run.to_s
            elapsed = 0
            every_in_seconds = next_run - started
          else
            every_in_seconds = @routines[@channel_id][name][:every_in_seconds]
            elapsed = Time.now - started
            @routines[@channel_id][name][:last_elapsed] = elapsed
            @routines[@channel_id][name][:next_run] = (started + every_in_seconds).to_s
          end
          @routines[@channel_id][name][:running] = true
          @routines[@channel_id][name][:sleeping] = (every_in_seconds - elapsed).ceil
          update_routines()
          sleep(@routines[@channel_id][name][:sleeping]) unless elapsed > every_in_seconds
        else
          if !@routines[@channel_id][name][:running]
            @routines[@channel_id][name][:running] = true
            update_routines()
          end
          sleep 30
        end
      end
    end
  end

end
