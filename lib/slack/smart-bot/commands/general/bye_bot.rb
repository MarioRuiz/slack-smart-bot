class SlackSmartBot

  def bye_bot(dest, from, display_name)
    if @status == :on
      save_stats(__method__)
      bye = ["Bye", "Bæ", "Good Bye", "Adiós", "Ciao", "Bless", "Bless bless", "Adeu"].sample
      respond "#{bye} #{display_name}", dest

      if @listening.key?(from)
        if Thread.current[:on_thread]
          @listening[from].delete(Thread.current[:thread_ts])
        else
          @listening[from].delete(dest)
        end
        @listening.delete(from) if @listening[from].empty?
      end
    end
  end
end
