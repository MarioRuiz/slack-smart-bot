class SlackSmartBot

    # help: ----------------------------------------------
    # help: `What's new`
    # help:    It will display the last user changes on Slack Smart Bot
    # help: command_id: :whats_new
    # help:
    def whats_new(user, dest, dchannel, from, display_name)
      if @status == :on
        save_stats(__method__)
        whats_new_file = (__FILE__).gsub(/lib\/slack\/smart-bot\/commands\/on_bot\/general\/whats_new\.rb$/, "whats_new.txt")
        whats_new = File.read(whats_new_file)
        whats_new.split(/^\-\-\-\-\-\-+$/).each do |msg|
            respond msg
            sleep 0.3
        end
      end
    end
  end
  