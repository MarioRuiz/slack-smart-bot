class SlackSmartBot
  # help: ----------------------------------------------
  # help: `delete shortcut NAME`
  # help: `delete sc NAME`
  # help:    It will delete the shortcut with the supplied name
  # help:

  def delete_shortcut(dest, user, shortcut, typem, command)
    save_stats(__method__)
    unless typem == :on_extended
      from = user.name
      if config[:allow_access].key?(__method__) and !config[:allow_access][__method__].include?(user.name) and !config[:allow_access][__method__].include?(user.id)
        respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
      else
        deleted = false

        if !config.admins.include?(from) and @shortcuts[:all].include?(shortcut) and !@shortcuts[from].include?(shortcut)
          respond "Only the creator of the shortcut or an admin user can delete it", dest
        elsif (@shortcuts.keys.include?(from) and @shortcuts[from].keys.include?(shortcut)) or
              (config.admins.include?(from) and @shortcuts[:all].include?(shortcut))
          #are you sure? to avoid deleting by mistake
          unless @questions.keys.include?(from)
            ask("are you sure you want to delete it?", command, from, dest)
          else
            case @questions[from]
            when /^(yes|yep)/i
              @questions.delete(from)
              respond "shortcut deleted!", dest
              respond("#{shortcut}: #{@shortcuts[from][shortcut]}", dest) if @shortcuts.key?(from) and @shortcuts[from].key?(shortcut)
              respond("#{shortcut}: #{@shortcuts[:all][shortcut]}", dest) if @shortcuts.key?(:all) and @shortcuts[:all].key?(shortcut)
              @shortcuts[from].delete(shortcut) if @shortcuts.key?(from) and @shortcuts[from].key?(shortcut)
              @shortcuts[:all].delete(shortcut) if @shortcuts.key?(:all) and @shortcuts[:all].key?(shortcut)
              update_shortcuts_file()
            when /^no/i
              @questions.delete(from)
              respond "ok, I won't delete it", dest
            else
              ask("I don't understand, are you sure you want to delete it? (yes or no)", command, from, dest)
            end
          end
        else
          respond "shortcut not found", dest
        end
      end
    end
  end
end
