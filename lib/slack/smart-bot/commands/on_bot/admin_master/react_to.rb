class SlackSmartBot

    # helpadmin: ----------------------------------------------
    # helpadmin: `react to #CHANNEL_NAME THREAD_ID EMOJIS`
    # helpadmin:    It will send the specified reactions as SmartBot
    # helpadmin:    You can use this command only if you are a Master admin user and if you are in a private conversation with the bot
    # helpadmin:     Examples:
    # helpadmin:       _react to #sales 1622550707.012100 :thumbsup:_
    # helpadmin:       _react to #sales p1622550707012100 :thumbsup:_
    # helpadmin:       _react to #sales p1622550707012100 :thumbsup: :heavy_check_mark: :bathtub:_
    # helpadmin:
    def react_to(dest, from, typem, to, thread_ts, emojis)
      save_stats(__method__)
      if config.masters.include?(from) and typem==:on_dm #master admin user
        emojis.split(' ').each do |emoji|
          react emoji, thread_ts, to
        end
        react :heavy_check_mark
      else
        respond "Only master admin users on a `pr`ivate conversation with the SmartBot can send reactions as SmartBot.", dest
      end
    end
end
  