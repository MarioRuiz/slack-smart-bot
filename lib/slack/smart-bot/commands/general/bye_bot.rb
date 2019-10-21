class SlackSmartBot

  # help: ----------------------------------------------
  # help: `Bye Bot`
  # help: `Bye Smart`
  # help: `Bye NAME_OF_THE_BOT`
  # help:    Also apart of Bye you can use _Bæ, Good Bye, Adiós, Ciao, Bless, Bless Bless, Adeu_
  # help:    Bot stops listening to you
  # help:
  def bye_bot(dest, from, display_name)
    if @status == :on
      bye = ["Bye", "Bæ", "Good Bye", "Adiós", "Ciao", "Bless", "Bless bless", "Adeu"].sample
      respond "#{bye} #{display_name}", dest
      @listening.delete(from)
    end
  end
end
