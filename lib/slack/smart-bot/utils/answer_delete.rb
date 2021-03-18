class SlackSmartBot
    def answer_delete(from = Thread.current[:user].name, dest = Thread.current[:dest])
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
  