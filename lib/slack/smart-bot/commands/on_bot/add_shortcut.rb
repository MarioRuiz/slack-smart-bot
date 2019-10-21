class SlackSmartBot

  # help: ----------------------------------------------
  # help: `add shortcut NAME: COMMAND`
  # help: `add sc NAME: COMMAND`
  # help: `add shortcut for all NAME: COMMAND`
  # help: `add sc for all NAME: COMMAND`
  # help: `shortcut NAME: COMMAND`
  # help: `shortcut for all NAME: COMMAND`
  # help:    It will add a shortcut that will execute the command we supply.
  # help:    In case we supply 'for all' then the shorcut will be available for everybody
  # help:    Example:
  # help:        _add shortcut for all Spanish account: code require 'iso/iban'; 10.times {puts ISO::IBAN.random('ES')}_
  # help:    Then to call this shortcut:
  # help:        _sc spanish account_
  # help:        _shortcut Spanish Account_
  # help:        _Spanish Account_
  # help:
  def add_shortcut(dest, from, typem, for_all, shortcut_name, command, command_to_run)
    unless typem == :on_extended
      @shortcuts[from] = Hash.new() unless @shortcuts.keys.include?(from)

      found_other = false
      if for_all.to_s != ""
        @shortcuts.each { |sck, scv|
          if sck != :all and sck != from and scv.key?(shortcut_name)
            found_other = true
          end
        }
      end
      if !ADMIN_USERS.include?(from) and @shortcuts[:all].include?(shortcut_name) and !@shortcuts[from].include?(shortcut_name)
        respond "Only the creator of the shortcut can modify it", dest
      elsif found_other
        respond "You cannot create a shortcut for all with the same name than other user is using", dest
      elsif !@shortcuts[from].include?(shortcut_name)
        #new shortcut
        @shortcuts[from][shortcut_name] = command_to_run
        @shortcuts[:all][shortcut_name] = command_to_run if for_all.to_s != ""
        update_shortcuts_file()
        respond "shortcut added", dest
      else

        #are you sure? to avoid overwriting existing
        unless @questions.keys.include?(from)
          ask("The shortcut already exists, are you sure you want to overwrite it?", command, from, dest)
        else
          case @questions[from]
          when /^(yes|yep)/i
            @shortcuts[from][shortcut_name] = command_to_run
            @shortcuts[:all][shortcut_name] = command_to_run if for_all.to_s != ""
            update_shortcuts_file()
            respond "shortcut added", dest
            @questions.delete(from)
          when /^no/i
            respond "ok, I won't add it", dest
            @questions.delete(from)
          else
            ask "I don't understand, yes or no?", command, from, dest
          end
        end
      end
    end
  end
end
