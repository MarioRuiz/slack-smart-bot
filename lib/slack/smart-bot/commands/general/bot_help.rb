class SlackSmartBot

  # help: ----------------------------------------------
  # help: `bot help`
  # help: `bot help COMMAND`
  # help: `bot rules`
  # help: `bot rules COMMAND`
  # help: `bot what can I do?`
  # help:    it will display this help
  # help:    if COMMAND supplied just help for that command
  # help:    `bot rules` will show only the specific rules for this channel.
  # help:
  def bot_help(user, from, dest, dchannel, specific, help_command, rules_file)
    help_message_rules = ""
    help_found = false

    message = ""

    help_message = get_help(rules_file, dest, from, specific)

    if help_command.to_s != ""
      help_message.split(/^\s*-------*$/).each do |h|
        if h.match?(/[`_]#{help_command}/i)
          respond h, dest
          help_found = true
        end
      end
    else
      if (dest[0] == "C") || (dest[0] == "G") and @rules_imported.key?(user.id) &&
                                                  @rules_imported[user.id].key?(dchannel) && @bots_created.key?(@rules_imported[user.id][dchannel])
        message = "*You are using rules from another channel: <##{@rules_imported[user.id][dchannel]}>. These are the specific commands for that channel:*"
      elsif dest[0] == "D" && @rules_imported.key?(user.id) && @rules_imported[user.id].key?(user.id) and
            @bots_created.key?(@rules_imported[user.id][user.id])
        message = "*You are using rules from another channel: <##{@rules_imported[user.id][user.id]}>. These are the specific commands for that channel:*"
      end
      respond message, dest
    end

    if (help_command.to_s == "")
      help_message.split(/^\s*=========*$/).each do |h|
        respond("#{"=" * 35}\n#{h}", dest) unless h.match?(/\A\s*\z/)
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
          eval(File.new(rules_file).read) if File.exist?(rules_file)
        end
      end
      if defined?(git_project) && (git_project.to_s != "") && (help_message_rules != "") && (help_command.to_s == "")
        respond "Git project: #{git_project}", dest
      else
        def git_project
          ""
        end

        def project_folder
          ""
        end
      end
    elsif help_command.to_s == ""
      respond "Slack Smart Bot Github project: https://github.com/MarioRuiz/slack-smart-bot", dest
    end
  end
end
