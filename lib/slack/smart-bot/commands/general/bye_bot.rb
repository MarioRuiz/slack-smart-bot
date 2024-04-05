class SlackSmartBot

  def bye_bot(dest, user, display_name)
    user_name = user.name
    team_id = user.team_id 
    team_id_user = team_id + "_" + user_name

    if @status == :on
      save_stats(__method__)
      bye = ["Bye", "Bæ", "Good Bye", "Adiós", "Ciao", "Bless", "Bless bless", "Adeu"].sample
      respond "#{bye} #{display_name}", dest

      if @listening.key?(team_id_user)
        if Thread.current[:on_thread]
          @listening[team_id_user].delete(Thread.current[:thread_ts])
        else
          @listening[team_id_user].delete(dest)
        end
        @listening.delete(team_id_user) if @listening[team_id_user].empty?
      end
    end
  end
end
