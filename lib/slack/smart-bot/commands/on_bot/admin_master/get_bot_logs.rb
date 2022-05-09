class SlackSmartBot

    # helpadmin: ----------------------------------------------
    # helpadmin: `get bot logs`
    # helpadmin:    To see the bot logs
    # helpadmin:    You can use this command only if you are a Master admin user and if you are in a private conversation with the bot
    # helpadmin: command_id: :get_bot_logs
    # helpadmin:
    def get_bot_logs(dest, from, typem)
      save_stats(__method__)
      if config.masters.include?(from) and typem==:on_dm #master admin user
        respond 'Remember this data is private'
        send_file(dest, "Logs for #{config.channel}", "#{config.path}/logs/#{config.log_file}", 'Remember this data is private', 'text/plain', "text")
      else
        respond "Only master admin users on a private conversation with the bot can get the bot logs.", dest
      end
    end
end
  