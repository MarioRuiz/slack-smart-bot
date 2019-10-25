class SlackSmartBot
  def bot_rules(dest, help_command, typem, rules_file, from)
    if typem == :on_extended or typem == :on_call #for the other cases above.
      help_filtered = get_help(rules_file, dest, from, true)

      if help_command.to_s != ""
        help_found = false
        help_filtered.split(/^\s*-------*$/).each do |h|
          if h.match?(/[`_]#{help_command}/i)
            respond h, dest
            help_found = true
          end
        end
        respond("I didn't find any command starting by `#{help_command}`", dest) unless help_found
      else
        message = "-\n\n\n===================================\n*Rules from channel #{config.channel}*\n"
        if typem == :on_extended
          message += "To run the commands on this extended channel, add `!` before the command.\n"
        end
        message += help_filtered
        respond message, dest
      end

      unless rules_file.empty?
        begin
          eval(File.new(config.path+rules_file).read) if File.exist?(config.path+rules_file)
        end
      end
      if defined?(git_project) and git_project.to_s != "" and help_message_rules != "" and help_command.to_s == ""
        respond "Git project: #{git_project}", dest
      else
        def git_project() "" end
        def project_folder() "" end
      end
    end
  end
end
