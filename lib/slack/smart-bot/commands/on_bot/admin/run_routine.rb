class SlackSmartBot

  # helpadmin: ----------------------------------------------
  # helpadmin: `run routine NAME`
  # helpadmin: `execute routine NAME`
  # helpadmin:    It will run the specified routine
  # helpadmin:    You can use this command only if you are an admin user
  # helpadmin:    NAME: one word to identify the routine
  # helpadmin:    Examples:
  # helpadmin:      _run routine example_
  # helpadmin:

  def run_routine(dest, from, name)
    if ADMIN_USERS.include?(from) #admin user
      if !ON_MASTER_BOT and dest[0] == "D"
        respond "It's only possible to run routines from MASTER channel from a direct message with the bot.", dest
      elsif @routines.key?(@channel_id) and @routines[@channel_id].key?(name)
        if @routines[@channel_id][name][:file_path] != ""
          if @routines[@channel_id][name][:file_path].match?(/\.rb$/i)
            ruby = "ruby "
          else
            ruby = ""
          end
          process_to_run = "#{ruby}#{Dir.pwd}#{@routines[@channel_id][name][:file_path][1..-1]}"
          process_to_run = ("cd #{project_folder} &&" + process_to_run) if defined?(project_folder)

          stdout, stderr, status = Open3.capture3(process_to_run)
          if stderr == ""
            unless stdout.match?(/\A\s*\z/)
              respond "routine *`#{name}`*: #{stdout}", @routines[@channel_id][name][:dest]
            end
          else
            respond "routine *`#{name}`*: #{stdout} #{stderr}", @routines[@channel_id][name][:dest]
          end
        else #command
          respond "routine *`#{name}`*: #{@routines[@channel_id][name][:command]}", @routines[@channel_id][name][:dest]
          started = Time.now
          treat_message({ channel: @routines[@channel_id][name][:dest],
                         user: @routines[@channel_id][name][:creator_id],
                         text: @routines[@channel_id][name][:command],
                         files: nil })
        end
        @routines[@channel_id][name][:last_elapsed] = (Time.now - started)
        @routines[@channel_id][name][:last_run] = started.to_s
        update_routines()
      else
        respond "There isn't a routine with that name: `#{name}`.\nCall `see routines` to see added routines", dest
      end
    else
      respond "Only admin users can run routines", dest
    end
  end
end
