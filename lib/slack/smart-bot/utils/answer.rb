class SlackSmartBot
    def answer(from = Thread.current[:user].name, dest = Thread.current[:dest])
        if @answer.key?(from)
            if Thread.current[:on_thread]
                dest = Thread.current[:thread_ts]
            end
            if @answer[from].key?(dest)
                return @answer[from][dest]
            else
                return ''
            end
        else
            return ''
        end
    end
  
  end
  