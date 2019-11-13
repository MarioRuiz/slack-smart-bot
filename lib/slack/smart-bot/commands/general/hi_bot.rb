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
      if Thread.current[:using_channel]!=''
        respond "You are using specific rules for channel: <##{Thread.current[:using_channel]}>", dest
      end
      @listening << from unless @listening.include?(from)
    end
  end
end
