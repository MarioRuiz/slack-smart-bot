class SlackSmartBot
    def answer_delete(user = Thread.current[:user], dest = Thread.current[:dest])
        if user.is_a?(String)
            if user.match?(/^[A-Z0-9]{7,11}_/)
                from = user
            else
                from = "#{config.team_id}_#{user}"
            end
        else
            from = "#{user.team_id}_#{user.name}"
        end
        if @answer.key?(from)
            if Thread.current[:on_thread]
                dest = Thread.current[:thread_ts]
            end
            if @answer[from].key?(dest)
                @answer[from].delete(dest)
            end
            @questions.delete(from) # to be backwards compatible #todo: remove when 2.0
        end
    end

  end
