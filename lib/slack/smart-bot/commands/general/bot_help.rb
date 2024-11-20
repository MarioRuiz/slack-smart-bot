class SlackSmartBot
  def bot_help(user, from, dest, dchannel, specific, help_command, rules_file, savestats: true, strict: false, send_to_file: false, return_output: false)
    save_stats(__method__) if savestats
    output = []
    if has_access?(__method__, user)
      help_found = false
      message = ""
      if help_command.to_s != ""
        help_command = "" if help_command.to_s.match?(/^\s*expanded\s*$/i) or help_command.to_s.match?(/^\s*extended\s*$/i)
        expanded = true
        message_not_expanded = ""
      else
        expanded = false
        message_not_expanded = "If you want to see the *expanded* version of *`bot help`* or *`bot rules`*, please call *`bot help expanded`* or *`bot rules expanded`*\n"
        message_not_expanded += "Also to get specific *expanded* help for a specific command or rule call *`bot help COMMAND`*\n"
      end
      expanded = true if Thread.current[:prompt].to_s != ""
      if send_to_file
        expanded = true
        message_not_expanded = ""
      end
      help_message = get_help(rules_file, dest, user, specific, expanded)
      commands = []
      commands_search = []
      if help_command.to_s != ""
        help_command.gsub!("?", "\\?") # for open ai commands
        help_message.gsub(/====+/, "-" * 30).split(/^\s*-------*$/).each do |h|
          if strict
            if h.match?(/`#{help_command}`/i) or h.match?(/^\s*command_id:\s+:#{help_command.gsub(" ", "_")}\s*$/)
              output << h
              help_found = true
              commands << h
              break
            end
          else
            if h.match?(/[`_]#{help_command}/i) or h.match?(/^\s*command_id:\s+:#{help_command.gsub(" ", "_")}\s*$/)
              output << h
              help_found = true
              commands << h
            elsif !h.match?(/\A\s*\*/) and !h.match?(/\A\s*=+/) #to avoid general messages for bot help *General commands...*
              all_found = true
              help_command.to_s.split(" ") do |hc|
                unless hc.match?(/^\s*\z/)
                  if !h.match?(/#{hc}/i)
                    all_found = false
                  end
                end
              end
            end
            commands_search << h if all_found
          end
        end
      else
        if Thread.current[:using_channel] != ""
          message += "*You are using rules from another channel: <##{Thread.current[:using_channel]}>. These are the specific commands for that channel:*"
        end
        output << message
      end

      if (help_command.to_s == "")
        help_message.split(/^\s*=========*$/).each do |h|
          unless h.match?(/\A\s*\z/)
            output << "#{"=" * 35}\n#{h}"
          end
        end
        if Thread.current[:typem] == :on_pg or Thread.current[:typem] == :on_pub
          if @bots_created.size > 0
            txt = "\nThese are the *SmartBots* running on this Slack workspace: *<##{@master_bot_id}>, <##{@bots_created.keys.join(">, <#")}>*\n"
            txt += "Join one channel and call *`bot rules`* to see specific commands for that channel or *`bot help`* to see all commands for that channel.\n"
            output << txt
          end
        end
      else
        if commands.size < 10 and help_command.to_s != "" and commands_search.size > 0
          commands_search.shuffle!
          (10 - commands.size).times do |n|
            unless commands_search[n].nil?
              output << commands_search[n]
              help_found = true
            end
          end
        end
        unless help_found
          if specific
            output << "I didn't find any rule with `#{help_command}`"
          else
            output << "I didn't find any command with `#{help_command}`"
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
          output << "Git project: #{git_project}"
        else
          def git_project
            ""
          end

          def project_folder
            ""
          end
        end
      elsif help_command.to_s == ""
        output << "Slack Smart Bot Github project: https://github.com/MarioRuiz/slack-smart-bot"
      end
      unless expanded
        output << message_not_expanded
      end
    end
    if output.join("\n").lines.count > 50 and dest[0] != "D" and !send_to_file
      dest = :on_thread
      output.unshift("Since there are many lines returned the results are returned on a thread by default.")
    end
    if send_to_file
      content = output.join("\n\n")
      content.gsub!(/\*<([^>]*)\|([^>]*)>\*/, '## [\2](\1)')
      content.gsub!(/^\s*(\*.+\*)\s*$/, '# \1')
      content.gsub!(/command_id:\s+:/, "### :")
      content = content.gsub("\n", "  \n").gsub(/\|[\w\s]*>/i, ">").gsub(/^\s*\-\-\-\-\-\-/, "\n------")
      dest == :on_thread ? dest_file = dchannel : dest_file = dest
      send_file(dest_file, "SmartBot Help", "", "smartbot_help.md", "text/markdown", "markdown", content: content)
    elsif return_output
      output.each do |h|
        h.gsub!(/^\s*command_id:\s+:\w+\s*$/, "")
        h.gsub!(/^\s*>.+$/, "") if help_command.to_s != ""
      end
      return output
    else
      output.each do |h|
        msg = h.gsub(/^\s*command_id:\s+:\w+\s*$/, "")
        msg.gsub!(/^\s*>.+$/, "") if help_command.to_s != ""
        unless msg.match?(/\A\s*\z/)
          respond msg, dest, unfurl_links: false, unfurl_media: false
        end
      end
    end
    return output.join("\n")
  end
end
