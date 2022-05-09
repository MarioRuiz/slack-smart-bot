class SlackSmartBot
  def save_stats(method, data: {})
    if has_access?(method, Thread.current[:user])
      if config.stats
        begin
          require "csv"
          if !File.exist?("#{config.stats_path}.#{Time.now.strftime("%Y-%m")}.log")
            CSV.open("#{config.stats_path}.#{Time.now.strftime("%Y-%m")}.log", "wb") do |csv|
              csv << ["date", "bot_channel", "bot_channel_id", "dest_channel", "dest_channel_id", "type_message", "user_name", "user_id", "text", "command", "files"]
            end
          end
          if data.empty?
            data = {
              dest: Thread.current[:dest],
              typem: Thread.current[:typem],
              user: Thread.current[:user],
              files: Thread.current[:files?],
              command: Thread.current[:command],
              routine: Thread.current[:routine],
            }
          end
          if method.to_s == "ruby_code" and data.files
            command_txt = "ruby"
          else
            command_txt = data.command
          end
          command_txt.gsub!(/```.+```/m, "```CODE```")
          command_txt = "#{command_txt[0..99]}..." if command_txt.size > 100

          if data.routine
            user_name = "routine/#{data.user.name}"
            user_id = "routine/#{data.user.id}"
          else
            user_name = data.user.name
            user_id = data.user.id
          end
          CSV.open("#{config.stats_path}.#{Time.now.strftime("%Y-%m")}.log", "a+") do |csv|
            csv << [Time.now, config.channel, @channel_id, @channels_name[data.dest], data.dest, data.typem, user_name, user_id, command_txt, method, data.files]
          end
        rescue Exception => exception
          @logger.fatal "There was a problem on the stats"
          @logger.fatal exception
        end
      end
    else
      sleep 0.2
      Thread.exit
    end
  end
end
