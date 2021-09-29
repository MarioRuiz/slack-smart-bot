class SlackSmartBot
  # help: ----------------------------------------------
  # help: `delete shortcut NAME`
  # help: `delete sc NAME`
  # help: `delete global sc NAME`
  # help:    It will delete the shortcut with the supplied name
  # help:    'global' or 'generic' can only be used on Master channel.
  # help:    <https://github.com/MarioRuiz/slack-smart-bot#shortcuts|more info>
  # help:

  def delete_shortcut(dest, user, shortcut, typem, command, global)
    save_stats(__method__)
    unless typem == :on_extended
      from = user.name
      if has_access?(__method__, user)
        deleted = false

        if global
          if !config.on_master_bot or typem != :on_master
            respond "It is only possible to delete global shortcuts from Master channel"
          else
            if !is_admin?(from) and @shortcuts_global[:all].include?(shortcut) and 
              (!@shortcuts_global.key?(from) or !@shortcuts_global[from].include?(shortcut))
              respond "Only the creator of the shortcut or an admin user can delete it"
            elsif (@shortcuts_global.key?(from) and @shortcuts_global[from].keys.include?(shortcut)) or
              (is_admin?(from) and @shortcuts_global[:all].include?(shortcut))
              
              respond "global shortcut deleted!", dest
              if @shortcuts_global.key?(from) and @shortcuts_global[from].key?(shortcut)
                respond("#{shortcut}: #{@shortcuts_global[from][shortcut]}", dest) 
              elsif @shortcuts_global.key?(:all) and @shortcuts_global[:all].key?(shortcut)
                respond("#{shortcut}: #{@shortcuts_global[:all][shortcut]}", dest)
              end
              @shortcuts_global[from].delete(shortcut) if @shortcuts_global.key?(from) and @shortcuts_global[from].key?(shortcut)
              @shortcuts_global[:all].delete(shortcut) if @shortcuts_global.key?(:all) and @shortcuts_global[:all].key?(shortcut)
              update_shortcuts_file()
            else
              respond 'shortcut not found'
            end
          end
        else
          if !is_admin?(from) and @shortcuts[:all].include?(shortcut) and 
            (!@shortcuts.key?(from) or !@shortcuts[from].include?(shortcut))
            respond "Only the creator of the shortcut or an admin user can delete it", dest
          elsif (@shortcuts.keys.include?(from) and @shortcuts[from].keys.include?(shortcut)) or
                (is_admin?(from) and @shortcuts[:all].include?(shortcut))
            #are you sure? to avoid deleting by mistake
            if answer.empty?
              ask("are you sure you want to delete it?", command, from, dest)
            else
              case answer
              when /^(yes|yep)/i
                answer_delete(from)
                respond "shortcut deleted!", dest
                if @shortcuts.key?(from) and @shortcuts[from].key?(shortcut)
                  respond("#{shortcut}: #{@shortcuts[from][shortcut]}", dest) 
                elsif @shortcuts.key?(:all) and @shortcuts[:all].key?(shortcut)
                  respond("#{shortcut}: #{@shortcuts[:all][shortcut]}", dest)
                end
                @shortcuts[from].delete(shortcut) if @shortcuts.key?(from) and @shortcuts[from].key?(shortcut)
                @shortcuts[:all].delete(shortcut) if @shortcuts.key?(:all) and @shortcuts[:all].key?(shortcut)
                update_shortcuts_file()
              when /^no/i
                answer_delete(from)
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
end
