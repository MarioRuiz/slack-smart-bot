class SlackSmartBot

  # helpadmin: ----------------------------------------------
  # helpadmin: `run routine NAME`
  # helpadmin: `execute routine NAME`
  # helpadmin:    It will run the specified routine
  # helpadmin:    You can use this command only if you are an admin user
  # helpadmin:    NAME: one word to identify the routine
  # helpadmin:    Examples:
  # helpadmin:      _run routine example_
  # helpadmin:    <https://github.com/MarioRuiz/slack-smart-bot#routines|more info>
  # helpadmin: command_id: :run_routine
  # helpadmin:

  def run_routine(dest, from, name)
    save_stats(__method__)
    if is_admin?
      if !config.on_master_bot and dest[0] == "D"
        respond "It's only possible to run routines from MASTER channel from a direct message with the bot.", dest
      elsif @routines.key?(@channel_id) and @routines[@channel_id].key?(name)
        File.delete "#{config.path}/routines/#{@channel_id}/#{name}_output.txt" if File.exist?("#{config.path}/routines/#{@channel_id}/#{name}_output.txt")
        if @routines[@channel_id][name][:file_path] != ""
          if @routines[@channel_id][name][:file_path].match?(/\.rb$/i)
            ruby = "ruby "
          else
            ruby = ""
          end
          started = Time.now
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
          message = respond "routine *`#{name}`*: #{@routines[@channel_id][name][:command]}", @routines[@channel_id][name][:dest], return_message: true
          started = Time.now
          data = { channel: @routines[@channel_id][name][:dest],
            user: @routines[@channel_id][name][:creator_id],
            text: @routines[@channel_id][name][:command],
            files: nil,
            routine_name: name, 
            routine_type: @routines[@channel_id][name][:routine_type],
            routine: true }
          if @routines[@channel_id][name][:command].match?(/^!!/) or @routines[@channel_id][name][:command].match?(/^\^/)
            data[:ts] = message.ts
          end  
          treat_message(data)
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
