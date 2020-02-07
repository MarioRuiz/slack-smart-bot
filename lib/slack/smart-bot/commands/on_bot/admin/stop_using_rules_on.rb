class SlackSmartBot

  # helpadmin: ----------------------------------------------
  # helpadmin: `stop using rules on CHANNEL_NAME`
  # helpadmin:    it will stop using the extended rules on the specified channel.
  # helpadmin:

  def stop_using_rules_on(dest, user, from, channel, typem)
    save_stats(__method__)
    unless typem == :on_extended
      if !config.admins.include?(from) #not admin
        respond "Only admins can extend or stop using the rules. Admins on this channel: #{config.admins}", dest
      else
        get_bots_created()
        if @bots_created[@channel_id][:extended].include?(channel)
          @bots_created[@channel_id][:extended].delete(channel)
          update_bots_file()
          respond "<@#{user.id}> removed the access to the rules of #{config.channel} from #{channel}.", @master_bot_id
          if @channels_id[channel][0] == "G"
            respond "The rules won't be accessible from *#{channel}* from now on.", dest
          else
            respond "The rules won't be accessible from *<##{@channels_id[channel]}>* from now on.", dest
          end
          respond "<@#{user.id}> removed the access to the rules of <##{@channel_id}> from this channel.", @channels_id[channel]
        else
          respond "The rules were not accessible from *#{channel}*", dest
        end
      end
    end
  end
end
