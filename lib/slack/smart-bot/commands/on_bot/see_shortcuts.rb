class SlackSmartBot
  # help: ----------------------------------------------
  # help: `see shortcuts`
  # help: `see sc`
  # help:    It will display the shortcuts stored for the user and for :all
  # help:
  def see_shortcuts(dest, user, typem)
    save_stats(__method__)
    from = user.name
    if config[:allow_access].key?(__method__) and !config[:allow_access][__method__].include?(user.name) and !config[:allow_access][__method__].include?(user.id)
      respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
    else
      unless typem == :on_extended
        msg = ""
        if @shortcuts[:all].keys.size > 0
          msg = "*Available shortcuts for all:*\n"
          @shortcuts[:all].each { |name, value|
            msg += "    _#{name}: #{value}_\n"
          }
          respond msg, dest
        end

        if @shortcuts.keys.include?(from) and @shortcuts[from].keys.size > 0
          new_hash = @shortcuts[from].dup
          @shortcuts[:all].keys.each { |k| new_hash.delete(k) }
          if new_hash.keys.size > 0
            msg = "*Available shortcuts for #{from}:*\n"
            new_hash.each { |name, value|
              msg += "    _#{name}: #{value}_\n"
            }
            respond msg, dest
          end
        end
        respond "No shortcuts found", dest if msg == ""
      end
    end
  end
end
