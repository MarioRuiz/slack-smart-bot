class SlackSmartBot

  # help: ----------------------------------------------
  # help: `bot help`
  # help: `bot help COMMAND`
  # help: `bot rules`
  # help: `bot rules COMMAND`
  # help: `bot help expanded`
  # help: `bot rules expanded`
  # help: `bot what can I do?`
  # help:    it will display this help. For a more detailed help call `bot help expanded` or `bot rules expanded`.
  # help:    if COMMAND supplied just help for that command
  # help:    you can use the option 'expanded' or the alias 'extended'
  # help:    `bot rules` will show only the specific rules for this channel.
  # help:    <https://github.com/MarioRuiz/slack-smart-bot#bot-help|more info>
  # help:
  def bot_help(user, from, dest, dchannel, specific, help_command, rules_file)
    save_stats(__method__)
    if config[:allow_access].key?(__method__) and !config[:allow_access][__method__].include?(user.name) and !config[:allow_access][__method__].include?(user.id) and 
      (!user.key?(:enterprise_user) or ( user.key?(:enterprise_user) and !config[:allow_access][__method__].include?(user[:enterprise_user].id)))
      respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
    else
      help_found = false

      message = ""
      if help_command.to_s != ''
        help_command = '' if help_command.to_s.match?(/^\s*expanded\s*$/i) or help_command.to_s.match?(/^\s*extended\s*$/i)
        expanded = true
        message_not_expanded = ''
      else
        expanded = false
        message_not_expanded = "If you want to see the *expanded* version of *`bot help`* or *`bot rules`*, please call *`bot help expanded`* or *`bot rules expanded`*\n"
        message_not_expanded += "Also to get specific *expanded* help for a specific command or rule call *`bot help COMMAND`*\n"
      end

      help_message = get_help(rules_file, dest, from, specific, expanded)

      if help_command.to_s != ""
        help_message.gsub(/====+/,'-'*30).split(/^\s*-------*$/).each do |h|
          if h.match?(/[`_]#{help_command}/i)
            respond h, dest, unfurl_links: false, unfurl_media: false
            help_found = true
          end
        end
      else
        if Thread.current[:using_channel]!=''
          message += "*You are using rules from another channel: <##{Thread.current[:using_channel]}>. These are the specific commands for that channel:*"
        end
        respond message, dest, unfurl_links: false, unfurl_media: false
      end

      if (help_command.to_s == "")
        help_message.split(/^\s*=========*$/).each do |h|
          unless h.match?(/\A\s*\z/)
            respond "#{"=" * 35}\n#{h}", dest, unfurl_links: false, unfurl_media: false
          end
        end
        if Thread.current[:typem] == :on_pg or Thread.current[:typem] == :on_pub
          if @bots_created.size>0
            txt = "\nThese are the *SmartBots* running on this Slack workspace: *<##{@master_bot_id}>, <##{@bots_created.keys.join('>, <#')}>*\n"
            txt += "Join one channel and call *`bot rules`* to see specific commands for that channel or *`bot help`* to see all commands for that channel.\n"
            respond txt, unfurl_links: false, unfurl_media: false
          end
        end
      else
        unless help_found
          if specific
            respond("I didn't find any rule starting by `#{help_command}`", dest)
          else
            respond("I didn't find any command starting by `#{help_command}`", dest)
          end
        end
      end

      if specific
        unless rules_file.empty?
          begin
            eval(File.new(config.path + rules_file).read) if File.exist?(config.path + rules_file)
          end
        end
        if defined?(git_project) && (git_project.to_s != "") && (help_command.to_s == "")
          respond "Git project: #{git_project}", dest, unfurl_links: false, unfurl_media: false
        else
          def git_project
            ""
          end

          def project_folder
            ""
          end
        end
      elsif help_command.to_s == ""
        respond "Slack Smart Bot Github project: https://github.com/MarioRuiz/slack-smart-bot", dest, unfurl_links: false, unfurl_media: false
      end
      respond(message_not_expanded, unfurl_media: false, unfurl_links: false) unless expanded
    end
  end
end
