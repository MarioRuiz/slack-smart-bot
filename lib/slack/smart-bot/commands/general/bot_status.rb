class SlackSmartBot
  # helpadmin: ----------------------------------------------
  # helpadmin: `bot status`
  # helpadmin:    Displays the status of the bot
  # helpadmin:    If on master channel and admin user also it will display info about bots created
  # helpadmin:
  def bot_status(dest, from)
    get_bots_created()
    gems_remote = `gem list slack-smart-bot --remote`
    version_remote = gems_remote.to_s().scan(/slack-smart-bot \((\d+\.\d+\.\d+)/).join
    version_message = ""
    if version_remote != VERSION
      version_message = " There is a new available version: #{version_remote}."
    end
    require "socket"
    ip_address = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address
    respond "*#{Socket.gethostname} (#{ip_address})*\n\tStatus: #{@status}.\n\tVersion: #{VERSION}.#{version_message}\n\tRules file: #{File.basename RULES_FILE}\n\tExtended: #{@bots_created[@channel_id][:extended] unless ON_MASTER_BOT}\n\tAdmins: #{ADMIN_USERS}\n\tBot time: #{Time.now}", dest
    if @status == :on
      respond "I'm listening to [#{@listening.join(", ")}]", dest
      if ON_MASTER_BOT and ADMIN_USERS.include?(from)
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
          if ON_MASTER_BOT and v.key?(:cloud) and v[:cloud]
            msg << "\trunner: `ruby #{$0} \"#{v[:channel_name]}\" \"#{v[:admins]}\" \"#{v[:rules_file]}\" on&`"
          end
          respond msg.join("\n"), dest
        end
        @pings = []
      end
    end
  end
end
