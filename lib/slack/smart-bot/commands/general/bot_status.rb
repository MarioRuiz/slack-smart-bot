class SlackSmartBot
  # helpadmin: ----------------------------------------------
  # helpadmin: `bot status`
  # helpadmin:    Displays the status of the bot
  # helpadmin:    If on master channel and admin user also it will display info about bots created
  # helpadmin:
  def bot_status(dest, user)
    save_stats(__method__)
    get_bots_created()
    if config[:allow_access].key?(__method__) and !config[:allow_access][__method__].include?(user.name) and !config[:allow_access][__method__].include?(user.id) and 
      (!user.key?(:enterprise_user) or ( user.key?(:enterprise_user) and !config[:allow_access][__method__].include?(user[:enterprise_user].id)))
      respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
    else
      gems_remote = `gem list slack-smart-bot --remote`
      version_remote = gems_remote.to_s().scan(/slack-smart-bot \((\d+\.\d+\.\d+)/).join
      version_message = ""
      if version_remote != VERSION
        version_message = " There is a new available version: #{version_remote}."
      end
      require "socket"
      ip_address = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address
      respond "*#{Socket.gethostname} (#{ip_address})*\n\tStatus: #{@status}.\n\tVersion: #{VERSION}.#{version_message}\n\tRules file: #{File.basename config.rules_file}\n\tExtended: #{@bots_created[@channel_id][:extended] unless config.on_master_bot}\n\tAdmins: #{config.admins}\n\tBot time: #{Time.now}", dest
      if @status == :on
        respond "I'm listening to [#{@listening.keys.join(", ")}]", dest
        if config.on_master_bot and config.admins.include?(user.name)
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
