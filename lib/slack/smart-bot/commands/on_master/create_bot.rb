class SlackSmartBot
  # helpmaster: ----------------------------------------------
  # helpmaster: `create bot on CHANNEL_NAME`
  # helpmaster: `create cloud bot on CHANNEL_NAME`
  # helpmaster: `create silent bot on CHANNEL_NAME`
  # helpmaster:    Creates a new bot on the channel specified
  # helpmaster:    It will work only if you are on Master channel
  # helpmaster:    The admins will be the master admins, the creator of the bot and the creator of the channel
  # helpmaster:    Follow the instructions in case creating cloud bots
  # helpmaster:    In case 'silent' won't display the Bot initialization message on the CHANNEL_NAME
  # helpmaster:    <https://github.com/MarioRuiz/slack-smart-bot#bot-management|more info>
  # helpmaster: command_id: :create_bot
  # helpmaster:
  def create_bot(dest, user, type, channel)
    cloud = type.include?('cloud')
    silent = type.include?('silent')
    save_stats(__method__)
    from = user.name
    if has_access?(__method__, user)
      if config.on_master_bot
        get_channels_name_and_id() unless @channels_name.keys.include?(channel) or @channels_id.keys.include?(channel)
        channel_id = nil
        if @channels_name.key?(channel) #it is an id
          channel_id = channel
          channel = @channels_name[channel_id]
        elsif @channels_id.key?(channel) #it is a channel name
          channel_id = @channels_id[channel]
        end
        #todo: add pagination for case more than 1000 channels on the workspace
        channels = get_channels()
        channel = @channels_name[channel] if @channels_name.key?(channel)
        channel_found = channels.detect { |c| c.name == channel }
        members = get_channel_members(@channels_id[channel]) unless channel_found.nil?

        if channel_id.nil?
          respond "There is no channel with that name: #{channel}, please be sure is written exactly the same", dest
        elsif channel == config.master_channel
          respond "There is already a bot in this channel: #{channel}", dest
        elsif @bots_created.keys.include?(channel_id)
          respond "There is already a bot in this channel: #{channel}, kill it before", dest
        elsif config[:nick_id] != channel_found.creator and !members.include?(config[:nick_id])
          respond "You need to add first to the channel the smart bot user: <@#{config[:nick_id]}>", dest
        else
          if channel_id != config[:channel]
            begin
              rules_file = "slack-smart-bot_rules_#{channel_id}_#{from.gsub(" ", "_")}.rb"
              if defined?(RULES_FOLDER) # consider removing RULES_FOLDER since we are not using it anywhere else
                rules_file = RULES_FOLDER + rules_file
                general_rules_file = RULES_FOLDER + 'general_rules.rb'
                general_commands_file = RULES_FOLDER + 'general_commands.rb'
              else
                Dir.mkdir("#{config.path}/rules") unless Dir.exist?("#{config.path}/rules")
                Dir.mkdir("#{config.path}/rules/#{channel_id}") unless Dir.exist?("#{config.path}/rules/#{channel_id}")
                rules_file = "/rules/#{channel_id}/" + rules_file
                general_rules_file = "/rules/general_rules.rb"
                general_commands_file = "/rules/general_commands.rb"
              end
              default_rules = (__FILE__).gsub(/slack\/smart-bot\/commands\/on_master\/create_bot\.rb$/, "slack-smart-bot_rules.rb")
              default_general_rules = (__FILE__).gsub(/slack\/smart-bot\/commands\/on_master\/create_bot\.rb$/, "slack-smart-bot_general_rules.rb")
              default_general_commands = (__FILE__).gsub(/slack\/smart-bot\/commands\/on_master\/create_bot\.rb$/, "slack-smart-bot_general_commands.rb")
              
              File.delete(config.path + rules_file) if File.exist?(config.path + rules_file)
              FileUtils.copy_file(default_rules, config.path + rules_file) unless File.exist?(config.path + rules_file)
              FileUtils.copy_file(default_general_rules, config.path + general_rules_file) unless File.exist?(config.path + general_rules_file)
              FileUtils.copy_file(default_general_commands, config.path + general_commands_file) unless File.exist?(config.path + general_commands_file)
              admin_users = Array.new()
              creator_info = @users.select{|u| u.id == channel_found.creator or (u.key?(:enterprise_user) and u.enterprise_user.id == channel_found.creator)}[-1]
              if creator_info.nil? or creator_info.empty? or creator_info.user.nil?
                admin_users = [from] + config.masters
              else
                admin_users = [from, creator_info.user.name] + config.masters
              end
              admin_users.uniq!
              @logger.info "BOT_SILENT=#{silent} ruby #{config.file_path} \"#{channel}\" \"#{admin_users.join(",")}\" \"#{rules_file}\" on"
          
              if cloud
                respond "Copy the bot folder to your cloud location and run `ruby #{config.file} \"#{channel}\" \"#{admin_users.join(",")}\" \"#{rules_file}\" on&`", dest
              else
                t = Thread.new do
                  `BOT_SILENT=#{silent} ruby #{config.file_path} \"#{channel}\" \"#{admin_users.join(",")}\" \"#{rules_file}\" on`
                end
              end
              @bots_created[channel_id] = {
                creator_name: from,
                channel_id: channel_id,
                channel_name: @channels_name[channel_id],
                status: :on,
                created: Time.now.strftime("%Y-%m-%dT%H:%M:%S.000Z")[0..18],
                rules_file: rules_file,
                admins: admin_users.join(","),
                extended: [],
                cloud: cloud,
                thread: t,
              }
              @bots_created[channel_id].silent = true if silent

              respond "The bot has been created on channel: #{channel}. Rules file: #{File.basename rules_file}. Admins: #{admin_users.join(", ")}", dest
              update_bots_file()
            rescue Exception => stack
              @logger.fatal stack
              message = "Problem creating the bot on channel #{channel}. Error: <#{stack}>."
              @logger.error message
              respond message, dest
            end
          else
            respond "There is already a bot in this channel: #{channel}, and it is the Master Channel!", dest
          end
        end
      else
        respond "Sorry I cannot create bots from this channel, please visit the master channel: <##{@master_bot_id}>", dest
      end
    end
  end
end
