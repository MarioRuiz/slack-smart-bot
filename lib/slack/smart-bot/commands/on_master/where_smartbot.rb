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
      extended = @bots_created.values.extended.flatten
      channels.each do |c|
        type = ''
        unless c.id[0] == "D"
            if @bots_created.key?(c.id)
                type = '_`(SmartBot)`_'
            elsif c.id == @master_bot_id
                type = '_`(Master)`_'
            elsif extended.include?(c.name)
                @bots_created.each do |bot,values|
                    if values.extended.include?(c.name)
                        type += "_`(Extended from ##{values.channel_name})`_ "
                    end
                end
            end
          if c.is_private?
            message << "#{c.id}: *##{c.name}* #{type}"
          else
            message << "#{c.id}: *<##{c.id}>* #{type}"
          end
        end
      end
      message.sort!
      respond "*<@#{config.nick_id}> is a member of:*\n\n#{message.join("\n")}"
    end
  end
end
