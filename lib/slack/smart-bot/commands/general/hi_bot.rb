class SlackSmartBot

  def hi_bot(user, dest, from, display_name)
    if @status == :on
      save_stats(__method__)
      user_name = user.name
      team_id = user.team_id
      team_id_user = team_id + "_" + user_name

      greetings = ["Hello", "Hallo", "Hi", "Hola", "What's up", "Hey", "Hæ"].sample
      respond "#{greetings} #{display_name}", dest
      if Thread.current[:typem] == :on_pub or Thread.current[:typem] == :on_pg
        respond "You are on a channel where the SmartBot is just a member. You can only run general bot commands.\nCall `bot help` to see the commands you can use."
      elsif Thread.current[:typem] == :on_extended
        message = ["You are on an extended channel from <##{@channel_id}> so you can use all specific commands from that channel just adding !, !! or ^ before the command."]
        message << "Call `bot help` to see the commands you can use."
        respond message.join("\n")
      elsif Thread.current[:typem] == :on_dm and Thread.current[:using_channel] == ''
        unless @bots_created.empty?
          respond "To start using the rules from a Bot channel call `use #CHANNEL`.\nAvailable SmartBots: <##{@bots_created.keys.join('>, <#')}>\nIf you want to call just one command from a specific channel: `#CHANNEL COMMAND`"
        end
      else
        respond "You are on <##{@channel_id}> SmartBot channel. Call `bot help` to see all commands you can use or `bot rules` just to see the specific commands for this Bot channel."
      end
      if Thread.current[:using_channel]!=''
        message = ["You are using rules from <##{Thread.current[:using_channel]}>"]
        message << "If you want to change bot channel rules call `use #CHANNEL` or `stop using rules from <##{Thread.current[:using_channel]}>` to stop using rules from this channel."
        message << "You can call a command from any other channel by calling `#CHANNEL COMMAND`" if Thread.current[:typem] == :on_dm
        respond message.join("\n")
      end
      @listening[team_id_user] = {} unless @listening.key?(team_id_user)
      if Thread.current[:on_thread]
        @listening[team_id_user][Thread.current[:thread_ts]] = Time.now
      else
        @listening[team_id_user][dest] = Time.now
      end
    end
  end
end
