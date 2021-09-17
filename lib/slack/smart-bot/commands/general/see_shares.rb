class SlackSmartBot

  def see_shares()
    save_stats(__method__)
    typem = Thread.current[:typem]
    dest = Thread.current[:dest]
    if typem == :on_call
      channel = Thread.current[:dchannel]
    else
      channel = Thread.current[:dest]
    end

    general_message = "\nRelated commands `share messages /RegExp/ on #CHANNEL`, `share messages \"TEXT\" on #CHANNEL`, `delete share ID`"
    if File.exist?("#{config.path}/shares/#{@channels_name[channel]}.csv")
      t = CSV.table("#{config.path}/shares/#{@channels_name[channel]}.csv", headers: ['share_id', 'user_deleted', 'user_created', 'date', 'time', 'type', 'to_channel', 'condition'])
      message =[]
      t.each do |m|
        if m[:user_deleted] == ''
          if m[:type]=='text'
            emoji = ":abc:"
          elsif m[:type] == 'regexp'
            emoji = ":heavy_plus_sign:"
          else
            emoji = ':white_square:'
          end
          message << "\t#{m[:share_id]} #{emoji} *_#{m[:date]}_* #{m[:time]} *#{m[:user_created]}* <##{@channels_id[m[:to_channel]]}|#{m[:to_channel]}> : \t`#{m[:condition]}`"
        end
      end
      if message.size == 0
        message << "*There are no active shares right now.*"
      else
        message.unshift("*Shares from channel <##{channel}>*")
      end
      message << general_message
      respond message.join("\n"), dest
    else
      respond "*There are no active shares right now.*#{general_message}"
    end

  end
end
