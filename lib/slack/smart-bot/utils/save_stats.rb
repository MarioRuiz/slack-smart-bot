class SlackSmartBot

    def save_stats(method)
        if config.stats
            begin
              require 'csv'
              if !File.exist?("#{config.stats_path}.#{Time.now.strftime("%Y-%m")}.log")
                CSV.open("#{config.stats_path}.#{Time.now.strftime("%Y-%m")}.log", 'wb') do |csv|
                    csv << ['date','bot_channel', 'bot_channel_id', 'dest_channel', 'dest_channel_id', 'type_message', 'user_name', 'user_id', 'text', 'command', 'files']
                end
              end
              dest = Thread.current[:dest]
              typem = Thread.current[:typem]
              user = Thread.current[:user]
              files = Thread.current[:files?]
              if method.to_s == 'ruby_code' and files
                command_txt = 'ruby'
              else
                command_txt = Thread.current[:command]
              end

              CSV.open("#{config.stats_path}.#{Time.now.strftime("%Y-%m")}.log", "a+") do |csv|
                csv << [Time.now, config.channel, @channel_id, @channels_name[dest], dest, typem, user.name, user.id, command_txt, method, files]
              end
            rescue Exception => exception
              @logger.fatal "There was a problem on the stats"
              @logger.fatal exception
            end
        end
    end

end  