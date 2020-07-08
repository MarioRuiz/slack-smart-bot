class SlackSmartBot

  def create_routine_thread(name)
    t = Thread.new do
      while @routines.key?(@channel_id) and @routines[@channel_id].key?(name)
        @routines[@channel_id][name][:thread] = Thread.current
        started = Time.now
        if @status == :on and @routines[@channel_id][name][:status] == :on
          @logger.info "Routine: #{@routines[@channel_id][name].inspect}"
          if @routines[@channel_id][name][:file_path].match?(/\.rb$/i)
            ruby = "ruby "
          else
            ruby = ""
          end
          @routines[@channel_id][name][:silent] = false if !@routines[@channel_id][name].key?(:silent)
          if @routines[@channel_id][name][:at] == "" or
             (@routines[@channel_id][name][:at] != "" and @routines[@channel_id][name][:running] and
              @routines[@channel_id][name][:next_run] != "" and Time.now.to_s >= @routines[@channel_id][name][:next_run])
            if @routines[@channel_id][name][:file_path] != ""
              process_to_run = "#{ruby}#{Dir.pwd}#{@routines[@channel_id][name][:file_path][1..-1]}"
              process_to_run = ("cd #{project_folder} &&" + process_to_run) if defined?(project_folder)

              stdout, stderr, status = Open3.capture3(process_to_run)
              if !@routines[@channel_id][name][:silent] or (@routines[@channel_id][name][:silent] and 
                (!stderr.match?(/\A\s*\z/) or !stdout.match?(/\A\s*\z/)))
                respond "routine *`#{name}`*: #{@routines[@channel_id][name][:file_path]}", @routines[@channel_id][name][:dest]
              end
              if stderr == ""
                unless stdout.match?(/\A\s*\z/)
                  respond stdout, @routines[@channel_id][name][:dest]
                end
              else
                respond "#{stdout} #{stderr}", @routines[@channel_id][name][:dest]
              end
            else #command
              if !@routines[@channel_id][name][:silent]
                respond "routine *`#{name}`*: #{@routines[@channel_id][name][:command]}", @routines[@channel_id][name][:dest]
              end
              started = Time.now
              data = { channel: @routines[@channel_id][name][:dest],
                user: @routines[@channel_id][name][:creator_id],
                text: @routines[@channel_id][name][:command],
                files: nil }
              treat_message(data)
            end
            # in case the routine was deleted while running the process
            if !@routines.key?(@channel_id) or !@routines[@channel_id].key?(name)
              Thread.exit
            end
            @routines[@channel_id][name][:last_run] = started.to_s
          end
          if @routines[@channel_id][name][:last_run] == "" and @routines[@channel_id][name][:next_run] != "" #for the first create_routine of one routine with at
            elapsed = 0
            require "time"
            every_in_seconds = Time.parse(@routines[@channel_id][name][:next_run]) - Time.now
          elsif @routines[@channel_id][name][:at] != "" #coming from start after pause for 'at'
            if @routines[@channel_id][name].key?(:dayweek) and @routines[@channel_id][name][:dayweek].to_s!=''
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
            else
              days = 0
              weekly = false
            end

            if started.strftime("%H:%M:%S") < @routines[@channel_id][name][:at] and days == 0
              nt = @routines[@channel_id][name][:at].split(":")
              next_run = Time.new(started.year, started.month, started.day, nt[0], nt[1], nt[2])
            else
              if days == 0 and started.strftime("%H:%M:%S") > @routines[@channel_id][name][:at]
                if weekly
                    days = 7
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
          sleep 30
        end
      end
    end
  end

end
