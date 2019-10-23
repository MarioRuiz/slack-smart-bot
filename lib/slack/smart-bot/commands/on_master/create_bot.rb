class SlackSmartBot
  # helpmaster: ----------------------------------------------
  # helpmaster: `create bot on CHANNEL_NAME`
  # helpmaster: `create cloud bot on CHANNEL_NAME`
  # helpmaster:    creates a new bot on the channel specified
  # helpmaster:    it will work only if you are on Master channel
  # helpmaster:    the admins will be the master admins, the creator of the bot and the creator of the channel
  # helpmaster:    follow the instructions in case creating cloud bots
  # helpmaster:
  def create_bot(dest, from, cloud, channel)
    if ON_MASTER_BOT
      get_channels_name_and_id() unless @channels_name.keys.include?(channel) or @channels_id.keys.include?(channel)
      channel_id = nil
      if @channels_name.key?(channel) #it is an id
        channel_id = channel
        channel = @channels_name[channel_id]
      elsif @channels_id.key?(channel) #it is a channel name
        channel_id = @channels_id[channel]
      end
      #todo: add pagination for case more than 1000 channels on the workspace
      channels = client.web_client.conversations_list(
        types: "private_channel,public_channel",
        limit: "1000",
        exclude_archived: "true",
      ).channels
      channel_found = channels.detect { |c| c.name == channel }
      members = client.web_client.conversations_members(channel: @channels_id[channel]).members unless channel_found.nil?

      if channel_id.nil?
        respond "There is no channel with that name: #{channel}, please be sure is written exactly the same", dest
      elsif channel == MASTER_CHANNEL
        respond "There is already a bot in this channel: #{channel}", dest
      elsif @bots_created.keys.include?(channel_id)
        respond "There is already a bot in this channel: #{channel}, kill it before", dest
      elsif config[:nick_id] != channel_found.creator and !members.include?(config[:nick_id])
        respond "You need to add first to the channel the smart bot user: #{config[:nick]}", dest
      else
        if channel_id != config[:channel]
          begin
            rules_file = "slack-smart-bot_rules_#{channel_id}_#{from.gsub(" ", "_")}.rb"
            if defined?(RULES_FOLDER)
              rules_file = RULES_FOLDER + rules_file
            else
              Dir.mkdir("rules") unless Dir.exist?("rules")
              Dir.mkdir("rules/#{channel_id}") unless Dir.exist?("rules/#{channel_id}")
              rules_file = "./rules/#{channel_id}/" + rules_file
            end
            default_rules = (__FILE__).gsub(/slack\/smart-bot\/commands\/on_master\/create_bot\.rb$/, "slack-smart-bot_rules.rb")
            File.delete(rules_file) if File.exist?(rules_file)
            FileUtils.copy_file(default_rules, rules_file) unless File.exist?(rules_file)
            admin_users = Array.new()
            creator_info = client.web_client.users_info(user: channel_found.creator)
            admin_users = [from, creator_info.user.name] + MASTER_USERS
            admin_users.uniq!
            @logger.info "ruby #{$0} \"#{channel}\" \"#{admin_users.join(",")}\" \"#{rules_file}\" on"
        
            if cloud
              respond "Copy the bot folder to your cloud location and run `ruby #{$0} \"#{channel}\" \"#{admin_users.join(",")}\" \"#{rules_file}\" on&`", dest
            else
              t = Thread.new do
                `ruby #{$0} \"#{channel}\" \"#{admin_users.join(",")}\" \"#{rules_file}\" on`
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
