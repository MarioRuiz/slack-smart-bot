class SlackSmartBot
  # help: ----------------------------------------------
  # help: `see shortcuts`
  # help: `see sc`
  # help:    It will display the shortcuts stored for the user and for :all
  # help:
  def see_shortcuts(dest, user, typem)
    save_stats(__method__)
    from = user.name
    if config[:allow_access].key?(__method__) and !config[:allow_access][__method__].include?(user.name) and !config[:allow_access][__method__].include?(user.id) and 
      (!user.key?(:enterprise_user) or ( user.key?(:enterprise_user) and !config[:allow_access][__method__].include?(user[:enterprise_user].id)))
      respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
    else
      unless typem == :on_extended
        msg = ""
        if @shortcuts[:all].keys.size > 0 or @shortcuts_global[:all].keys.size > 0
          msg = "*Available shortcuts for all:*\n"
          
          if @shortcuts[:all].keys.size > 0
            @shortcuts[:all].each { |name, value|
              msg += "    _#{name}: #{value}_\n"
            }
          end
          if @shortcuts_global[:all].keys.size > 0
            @shortcuts_global[:all].each { |name, value|
              msg += "    _#{name} (global): #{value}_\n"
            }
          end
          respond msg, dest
        end
        msg2 = ''
        if @shortcuts.keys.include?(from) and @shortcuts[from].keys.size > 0
          new_hash = @shortcuts[from].dup
          @shortcuts[:all].keys.each { |k| new_hash.delete(k) }
          if new_hash.keys.size > 0
            msg2 = "*Available shortcuts for #{from}:*\n"
            new_hash.each { |name, value|
              msg2 += "    _#{name}: #{value}_\n"
            }
          end
        end
        if @shortcuts_global.keys.include?(from) and @shortcuts_global[from].keys.size > 0
          new_hash = @shortcuts_global[from].dup
          @shortcuts_global[:all].keys.each { |k| new_hash.delete(k) }
          if new_hash.keys.size > 0
            msg2 = "*Available shortcuts for #{from}:*\n" if msg2 == ''
            new_hash.each { |name, value|
              msg2 += "    _#{name} (global): #{value}_\n"
            }
          end
        end
        respond msg2 unless msg2 == ''
        respond "No shortcuts found" if (msg + msg2) == ""
      end
    end
  end
end
