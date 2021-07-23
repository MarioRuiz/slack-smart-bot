class SlackSmartBot
  def see_favorite_commands(user, only_mine)
    save_stats(__method__)
    if config.stats
      if Thread.current[:using_channel].to_s==''
        channel = Thread.current[:dest]
      else
        channel = Thread.current[:using_channel]
      end
      files = Dir["#{config.stats_path}.*.log"].sort.reverse[0..1]
      if files.empty?
        respond "There is no data stored."
      else
        count_commands = {}
        files.each do |file|
          CSV.foreach(file, headers: true, header_converters: :symbol, converters: :numeric) do |row|
            row[:dest_channel_id] = row[:bot_channel_id] if row[:dest_channel_id].to_s[0] == "D"
            
            if ((only_mine and row[:user_name]==user.name) or (!only_mine and !config.admins.include?(row[:user_name]))) and 
              row[:dest_channel_id] == channel and !row[:user_name].include?('routine/') and 
              row[:command] != 'dont_understand'

              row[:command] = 'bot_help' if row[:command] == 'bot_rules'
              count_commands[row[:command]] ||= 0
              count_commands[row[:command]] += 1
            end
          end
        end
        commands = []
        count_commands.sort_by {|k,v| -v}.each do |command, num|
          commands << command
        end
        if commands.empty?
          respond "There is no data stored."
        else
          output = ""
          i = 0
          commands.each do |command|
            unless output.match?(/^\s*command_id:\s+:#{command}\s*$/)
              i+=1
              output += bot_help(user, user.name, Thread.current[:dest], channel, false, command.gsub('_',' '), config.rules_file, false)
              break if i>=5
            end
          end
        end
      end
    else
      respond "Ask an admin to set stats to true to generate the stats when running the bot instance so you can get this command to work."
    end
  end
end
