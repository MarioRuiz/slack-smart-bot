class SlackSmartBot
  # helpadmin: ----------------------------------------------
  # helpadmin: `bot status`
  # helpadmin:    Displays the status of the bot
  # helpadmin:    If on master channel and admin user also it will display info about bots created
  # helpadmin:    <https://github.com/MarioRuiz/slack-smart-bot#bot-management|more info>
  # helpadmin: command_id: :bot_status
  # helpadmin:
  def bot_status(dest, user)
    save_stats(__method__)
    get_bots_created()
    if has_access?(__method__, user)
      gems_remote = `gem list slack-smart-bot --remote`
      version_remote = gems_remote.to_s().scan(/slack-smart-bot \((\d+\.\d+\.\d+)/).join
      version_message = ""
      if Gem::Version.new(version_remote) > Gem::Version.new(VERSION)
        version_message = " There is a new available version: #{version_remote}."
      end
      require "socket"
      ip_address = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address
      respond "*#{Socket.gethostname} (#{ip_address})*\n\tStatus: #{@status}.\n\tVersion: #{VERSION}.#{version_message}\n\tRules file: #{File.basename config.rules_file}\n\tExtended: #{@bots_created[@channel_id][:extended] unless config.on_master_bot}\n\tAdmins: #{config.admins}\n\tBot time: #{Time.now}", dest
      if @status == :on
        #@listening.keys delete :threads key
        listening_keys = @listening.keys - [:threads]
        #remove team id from keys, key is a symbol
        listening_keys = listening_keys.map{|k| k.to_s.gsub(user.team_id+"_",'').to_sym}
        respond "I'm listening to [#{listening_keys.join(", ")}]", dest
        if config.on_master_bot and config.team_id_admins.include?("#{user.team_id}_#{user.name}")
          sleep 5
          @bots_created.each do |k, v|
            msg = []
            msg << "`#{v[:channel_name]}` (#{k}):"
            msg << "\tcreator: #{v[:creator_name]}"
            msg << "\tadmins: #{v[:admins]}"
            msg << "\tstatus: #{v[:status]} #{" *(not responded)*" unless @pings.include?(v[:channel_name])}"
            msg << "\tcreated: #{v[:created]}"
            msg << "\trules: #{v[:rules_file]}"
            msg << "\textended: #{v[:extended]}"
            msg << "\tcloud: #{v[:cloud]}"
            if config.on_master_bot and v.key?(:cloud) and v[:cloud]
              msg << "\trunner: `ruby #{config.file} \"#{v[:channel_name]}\" \"#{v[:admins]}\" \"#{v[:rules_file]}\" on&`"
            end
            respond msg.join("\n"), dest
          end
          @pings = []
        end
      end
    end
  end
end
