class SlackSmartBot

  # help: ----------------------------------------------
  # help: `Hi Bot`
  # help: `Hi Smart`
  # help: `Hello Bot` `Hola Bot` `Hallo Bot` `What's up Bot` `Hey Bot` `Hæ Bot`
  # help: `Hello THE_NAME_OF_THE_BOT`
  # help:    Also apart of Hello you can use _Hallo, Hi, Hola, What's up, Hey, Hæ_
  # help:    Bot starts listening to you
  # help:    After that if you want to avoid a single message to be treated by the smart bot, start the message by -
  # help:
  def hi_bot(user, dest, dchannel, from, display_name)
    if @status == :on
      greetings = ["Hello", "Hallo", "Hi", "Hola", "What's up", "Hey", "Hæ"].sample
      respond "#{greetings} #{display_name}", dest
      if @rules_imported.key?(user.id) and @rules_imported[user.id].key?(user.id) and dest[0] == "D"
        respond "You are using specific rules for channel: <##{@rules_imported[user.id][user.id]}>", dest
      elsif @rules_imported.key?(user.id) and @rules_imported[user.id].key?(dchannel) and (dest[0] == "C" or dest[0] == "G")
        respond "You are using specific rules for channel: <##{@rules_imported[user.id][dchannel]}>", dest
      end
      @listening << from unless @listening.include?(from)
    end
  end
end
