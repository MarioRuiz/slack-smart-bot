class SlackSmartBot
  #todo: reaction type not added yet since RTM doesn't support it. See if we can add it as an event
  def share_messages(user, from_channel, to_channel, condition)
    save_stats(__method__)
    if has_access?(__method__, user)
      #todo: add a @shared variable to control not to be shared more than once when using reactions
      #todo: it is only possible to share if smartbot is a member in both channels and the person adding the share command also
      if Thread.current[:typem] == :on_call or Thread.current[:typem] == :on_dm
        respond "You can use this command only from the source channel."
      elsif from_channel == to_channel
        respond "You cannot share messages on the same channel than source channel."
      else
        channels = get_channels(types: 'public_channel')
        channel_found = channels.detect { |c| c.name == from_channel }
        get_channels_name_and_id() unless @channels_id.key?(to_channel)
        channel_found = false if !@channels_id.key?(to_channel)
        if channel_found 
          members = get_channel_members(@channels_id[to_channel])
          if members.include?(config.nick_id) and members.include?(user.id)
            if condition.match?(/^\/.+\/$/)
              type = :regexp
            elsif condition.match?(/^".+"$/) or condition.match?(/^'.+'$/)
              type = :text
            else
              type = :reaction
            end
            if File.exist?("#{config.path}/shares/#{from_channel}.csv")
              t = CSV.table("#{config.path}/shares/#{from_channel}.csv", headers: ['share_id', 'user_deleted', 'user_created', 'date', 'time', 'type', 'to_channel', 'condition'])
              @shares[from_channel] = t
              if t.size>0
                num = t[:share_id].max + 1
              else
                num = 1
              end
            elsif !@shares.key?(from_channel)
              File.open("#{config.path}/shares/#{from_channel}.csv","w")
              t = CSV.table("#{config.path}/shares/#{from_channel}.csv", headers: ['share_id', 'user_deleted', 'user_created', 'date', 'time', 'type', 'to_channel', 'condition'])
              num = 1
              @shares[from_channel] = t
            else
              num = @shares[from_channel][:share_id].max + 1
            end
            values = [num, '', user.name, Time.now.strftime("%Y/%m/%d"), Time.now.strftime("%H:%M"), type.to_s, to_channel, condition]
            @shares[from_channel] << values
            CSV.open("#{config.path}/shares/#{from_channel}.csv", "a+") do |csv|
              csv << values
            end
            respond "*Share command*: id:#{num} Messages #{condition} will be shared from now on. Related commands `see shares`, `delete share ID`"
          else
            respond "*Share command*: The channel ##{to_channel} need to exist and the SmartBot and you have to be members."
          end
        else
          respond "*Share command*: The channel <##{@channels_id[from_channel]}|#{from_channel}> has to be a public channel and the destination channel has to be a valid channel."
        end
      end
    end
  end
end
