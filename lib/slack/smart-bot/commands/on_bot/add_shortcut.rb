class SlackSmartBot

  # help: ----------------------------------------------
  # help: `add shortcut NAME: COMMAND`
  # help: `add sc NAME: COMMAND`
  # help: `add shortcut for all NAME: COMMAND`
  # help: `add sc for all NAME: COMMAND`
  # help: `shortcut NAME: COMMAND`
  # help: `shortcut for all NAME: COMMAND`
  # help: `add global sc for all NAME: COMMAND`
  # help:    It will add a shortcut that will execute the command we supply.
  # help:    In case we supply 'for all' then the shorcut will be available for everybody
  # help:    If 'global' or 'generic' supplied and in Master channel then the shortcut will be available in all Bot channels.
  # help:    If you want to use a shortcut as a inline shortcut inside a command you can do it by adding a $ fex: _!run tests $cust1_
  # help:    Example:
  # help:        _add shortcut for all Spanish account: code require 'iso/iban'; 10.times {puts ISO::IBAN.random('ES')}_
  # help:    Then to call this shortcut:
  # help:        _sc spanish account_
  # help:        _shortcut Spanish Account_
  # help:        _Spanish Account_
  # help:
  def add_shortcut(dest, user, typem, for_all, shortcut_name, command, command_to_run, global)
    save_stats(__method__)
    unless typem == :on_extended
      from = user.name
      if config[:allow_access].key?(__method__) and !config[:allow_access][__method__].include?(user.name) and !config[:allow_access][__method__].include?(user.id) and 
        (!user.key?(:enterprise_user) or ( user.key?(:enterprise_user) and !config[:allow_access][__method__].include?(user[:enterprise_user].id)))
        respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
      else

        if global 
          if !config.on_master_bot or typem != :on_master
            respond "It is only possible to add global shortcuts from Master channel"
          else
            @shortcuts_global[from] = Hash.new() unless @shortcuts_global.keys.include?(from)
            found_other = false
            if for_all.to_s != ""
              @shortcuts_global.each { |sck, scv|
                if sck != :all and sck != from and scv.key?(shortcut_name)
                  found_other = true
                end
              }
            end
            if @shortcuts_global[:all].include?(shortcut_name) or @shortcuts_global[from].include?(shortcut_name)
              respond "Global shortcut name already in use. Please use another shortcut name."
            elsif found_other
              respond "You cannot create a global shortcut for all with the same name than other user is using."
            elsif !@shortcuts_global[from].include?(shortcut_name)
              #new shortcut
              @shortcuts_global[from][shortcut_name] = command_to_run
              @shortcuts_global[:all][shortcut_name] = command_to_run if for_all.to_s != ""
              update_shortcuts_file()
              respond "global shortcut added"
            else
              respond "Not possible to add the global shortcut" #todo: check if this is ever gonna be the case
            end            
          end
        else
          @shortcuts[from] = Hash.new() unless @shortcuts.keys.include?(from)

          found_other = false
          if for_all.to_s != ""
            @shortcuts.each { |sck, scv|
              if sck != :all and sck != from and scv.key?(shortcut_name)
                found_other = true
              end
            }
          end
          if !config.admins.include?(from) and @shortcuts[:all].include?(shortcut_name) and !@shortcuts[from].include?(shortcut_name)
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
            if answer.empty?
              ask("The shortcut already exists, are you sure you want to overwrite it?", command, from, dest)
            else
              case answer
              when /^(yes|yep)/i
                @shortcuts[from][shortcut_name] = command_to_run
                @shortcuts[:all][shortcut_name] = command_to_run if for_all.to_s != ""
                update_shortcuts_file()
                respond "shortcut added", dest
                answer_delete(from)
              when /^no/i
                respond "ok, I won't add it", dest
                answer_delete(from)
              else
                ask "I don't understand, yes or no?", command, from, dest
              end
            end
          end
        end
      end
    end
  end
end
