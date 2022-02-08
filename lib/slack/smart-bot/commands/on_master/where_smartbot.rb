class SlackSmartBot
  # helpmaster: ----------------------------------------------
  # helpmaster: `where is smartbot?`
  # helpmaster: `which channels smartbot?`
  # helpmaster: `where is a member smartbot?`
  # helpmaster:    It will list all channels where the smartbot is a member.
  # helpmaster: command_id: :where_smartbot
  # helpmaster:
  def where_smartbot(user)
    #todo: add tests
    save_stats(__method__)
    if has_access?(__method__, user)
      channels = get_channels(bot_is_in: true)
      message = []
      channels.each do |c|
        unless c.id[0] == "D"
          if c.is_private?
            message << "#{c.id}: *##{c.name}*"
          else
            message << "#{c.id}: *<##{c.id}>*"
          end
        end
      end
      message.sort!
      respond "<@#{config.nick_id}> is a member of:\n#{message.join("\n")}"
    end
  end
end
