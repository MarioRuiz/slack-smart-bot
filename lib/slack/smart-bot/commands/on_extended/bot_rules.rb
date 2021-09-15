class SlackSmartBot
  def bot_rules(dest, help_command, typem, rules_file, user)
    save_stats(__method__)
    from = user.name
    if has_access?(__method__, user)
      if typem == :on_extended or typem == :on_call #for the other cases above.

        if help_command.to_s != ''
          help_command = '' if help_command.to_s.match?(/^\s*expanded\s*$/i) or help_command.to_s.match?(/^\s*extended\s*$/i)
          expanded = true
        else
          expanded = false
        end 
  
        help_filtered = get_help(rules_file, dest, from, true, expanded)

        commands = []
        commands_search = []
        if help_command.to_s != ""
          help_found = false
          help_filtered.split(/^\s*-------*$/).each do |h|
            if h.match?(/[`_]#{help_command}/i)
              respond "*#{config.channel}*:#{h}", dest, unfurl_links: false, unfurl_media: false
              help_found = true
              commands << h
            elsif !h.match?(/\A\s*\*/) and !h.match?(/\A\s*=+/) #to avoid general messages for bot help *General rules...*
              all_found = true
              help_command.to_s.split(' ') do |hc|
                unless hc.match?(/^\s*\z/)
                  if !h.match?(/#{hc}/i)
                    all_found = false                  
                  end
                end
              end
              commands_search << h if all_found
            end
          end
          if commands.size < 5 and help_command.to_s!='' and commands_search.size > 0
            commands_search.shuffle!
            (5-commands.size).times do |n|
              unless commands_search[n].nil?
                respond commands_search[n].gsub(/^\s*command_id:\s+:\w+\s*$/,''), dest, unfurl_links: false, unfurl_media: false
                help_found = true
              end
            end
          end
          unless help_found
            respond "*#{config.channel}*: I didn't find any command with `#{help_command}`", dest, unfurl_links: false, unfurl_media: false
          end

        else
          message = "-\n\n\n===================================\n*Rules from channel #{config.channel}*\n"
          if typem == :on_extended
            message += "To run the commands on this extended channel, add `!`, `!!` or `^` before the command.\n"
          end
          message += help_filtered
          respond message, dest, unfurl_links: false, unfurl_media: false
        end

        unless rules_file.empty?
          begin
            eval(File.new(config.path+rules_file).read) if File.exist?(config.path+rules_file)
          end
        end
        if defined?(git_project) and git_project.to_s != "" and help_command.to_s == ""
          respond "Git project: #{git_project}", dest, unfurl_links: false, unfurl_media: false
        else
          def git_project() "" end
          def project_folder() "" end
        end
        unless expanded
          message_not_expanded = "If you want to see the *expanded* version of *`bot rules`*, please call  *`bot rules expanded`*\n"
          message_not_expanded += "Also to get specific *expanded* help for a specific command or rule call *`bot rules COMMAND`*\n"
          respond message_not_expanded, unfurl_links: false, unfurl_media: false
        end
      end
    end
  end
end
