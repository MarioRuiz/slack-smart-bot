class SlackSmartBot

    def save_status(status, status_id, message)
      require 'csv'
      Dir.mkdir("#{config.path}/status") unless Dir.exist?("#{config.path}/status")

      CSV.open("#{config.path}/status/#{config.channel}_status.csv", "a+") do |csv|
        csv << [Time.now.strftime("%Y/%m/%d"), Time.now.strftime("%H:%M:%S"), status, status_id, message]
      end
      if status_id == :disconnected
        Thread.new do
          sleep 50
          @logger.info "check disconnection 50 scs later #{@last_notified_status_id}"
          unless @last_notified_status_id == :connected
            respond ":red_circle: The *SmartBot* on *<##{@channel_id}|#{config.channel}>* is down. An admin will take a look. <@#{config.admins.join(">, <@")}>", config.status_channel
          end
        end
      end
      if @channels_id.is_a?(Hash) and @channels_id.keys.include?(config.status_channel)
        is_back = false
        m = ''
        if (Time.now-@last_status_change) > 20 or !defined?(@last_notified_status_id)
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
        end
        @last_status_change = Time.now
        @last_notified_status_id = status_id
        unless m == ''
          respond m, config.status_channel
        end
      end


    end

end  