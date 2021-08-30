class SlackSmartBot

    def save_status(status, status_id, message)
      require 'csv'
      Dir.mkdir("#{config.path}/status") unless Dir.exist?("#{config.path}/status")

      CSV.open("#{config.path}/status/#{config.channel}_status.csv", "a+") do |csv|
        csv << [Time.now.strftime("%Y/%m/%d"), Time.now.strftime("%H:%M"), status, status_id, message]
      end
      if @channels_id.is_a?(Hash) and @channels_id.keys.include?(config.status_channel)
        is_back = false
        m = ''
        if (Time.now-@last_status_change) > 60 or !defined?(@last_notified_status_id)
          if status_id == :connected
            if defined?(@last_notified_status_id)
              m = ":exclamation: :large_green_circle: The *SmartBot* on *<##{@channel_id}|#{config.channel}>* was not available for #{(Time.now-@last_status_change).round(0)} secs. *Now it is up and running again.*" 
            else
              m = ":large_green_circle: The *SmartBot* on *<##{@channel_id}|#{config.channel}>* is up and running again." 
            end
          end
        end
        if status_id == :paused
          m = ":red_circle: #{message} *<##{@channel_id}|#{config.channel}>*"
        elsif status_id == :started
          m = ":large_green_circle: #{message} *<##{@channel_id}|#{config.channel}>*"            
        elsif status_id == :killed or status_id == :exited
          m = ":red_circle: #{message}"
        elsif config.on_master_bot and status_id == :maintenance_on
          m = ":red_circle: The *SmartBot* is on maintenance so not possible to attend any request."
        elsif config.on_master_bot and status_id == :maintenance_off
          m = ":large_green_circle: The *SmartBot* is up and running again."
        elsif status == :off and status_id != @last_notified_status_id
          current_status = @last_notified_status_id
          sleep 20
          if @last_notified_status_id == :connected
            is_back = true
          else
            m = ":red_circle: The *SmartBot* on *<##{@channel_id}|#{config.channel}>* is down. An admin will take a look. <@#{config.admins.join(">, <@")}>"
          end
        end
        @last_status_change = Time.now
        @last_notified_status_id = status_id unless is_back
        unless m == ''
          respond m, config.status_channel
        end
      end


    end

end  