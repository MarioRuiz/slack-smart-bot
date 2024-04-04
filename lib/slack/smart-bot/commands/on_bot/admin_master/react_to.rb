class SlackSmartBot

    # helpadmin: ----------------------------------------------
    # helpadmin: `react to #CHANNEL_NAME THREAD_ID EMOJIS`
    # helpadmin: `react to URL EMOJIS`
    # helpadmin:    It will send the specified reactions as SmartBot
    # helpadmin:    You can use this command only if you are a Master admin user and if you are in a private conversation with the bot
    # helpadmin:     Examples:
    # helpadmin:       _react to #sales 1622550707.012100 :thumbsup:_
    # helpadmin:       _react to #sales p1622550707012100 :thumbsup:_
    # helpadmin:       _react to #sales p1622550707012100 :thumbsup: :heavy_check_mark: :bathtub:_
    # helpadmin: command_id: :react_to
    # helpadmin:
    def react_to(dest, user, typem, to, thread_ts, emojis)
      save_stats(__method__)
      if config.team_id_masters.include?("#{user.team_id}_#{user.name}") and typem==:on_dm #master admin user
        succs = []
        emojis.split(' ').each do |emoji|
          succs << (react emoji, thread_ts, to)
        end
        succs.uniq!
        if succs.size == 1 and succs[0] == true
          react :heavy_check_mark
        elsif succs.size == 2
          react :exclamation
        else
          react :x
        end
      else
        respond "Only master admin users on a private conversation with the SmartBot can send reactions as SmartBot.", dest
      end
    end
end
