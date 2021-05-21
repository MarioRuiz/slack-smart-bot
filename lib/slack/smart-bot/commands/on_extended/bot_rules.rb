class SlackSmartBot
  def bot_rules(dest, help_command, typem, rules_file, user)
    save_stats(__method__)
    from = user.name
    if config[:allow_access].key?(__method__) and !config[:allow_access][__method__].include?(user.name) and !config[:allow_access][__method__].include?(user.id) and 
      (!user.key?(:enterprise_user) or ( user.key?(:enterprise_user) and !config[:allow_access][__method__].include?(user[:enterprise_user].id)))
      respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
    else
      if typem == :on_extended or typem == :on_call #for the other cases above.

        if help_command.to_s != ''
          help_command = '' if help_command.to_s.match?(/^\s*expanded\s*$/i) or help_command.to_s.match?(/^\s*extended\s*$/i)
          expanded = true
        else
          expanded = false
        end 
  
        help_filtered = get_help(rules_file, dest, from, true, expanded)

        if help_command.to_s != ""
          help_found = false
          help_filtered.split(/^\s*-------*$/).each do |h|
            if h.match?(/[`_]#{help_command}/i)
              respond "*#{config.channel}*:#{h}", dest, unfurl_links: false, unfurl_media: false
              help_found = true
            end
          end
          unless help_found
            respond "*#{config.channel}*: I didn't find any command starting by `#{help_command}`", dest, unfurl_links: false, unfurl_media: false
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
