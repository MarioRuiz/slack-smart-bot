class SlackSmartBot

  #to send messages without listening for a response to users
  def send_msg_user(id_user, msg)
    unless msg == ""
      if id_user[0] == "D"
        if config[:simulate]
          open("#{config.path}/buffer_complete.log", "a") { |f|
            f.puts "|#{id_user}|#{config[:nick_id]}|#{config[:nick]}|#{msg}~~~"
          }
        else  
          if Thread.current[:on_thread]
            client.message(channel: id_user, as_user: true, text: msg, thread_ts: Thread.current[:thread_ts])
          else
            client.message(channel: id_user, as_user: true, text: msg)
          end
        end
        if config[:testing] and config.on_master_bot
          open("#{config.path}/buffer.log", "a") { |f|
            f.puts "|#{id_user}|#{config[:nick_id]}|#{config[:nick]}|#{msg}"
          }
        end
      else
        im = client.web_client.im_open(user: id_user)
        if config[:simulate]
          open("#{config.path}/buffer_complete.log", "a") { |f|
            f.puts "|#{im["channel"]["id"]}|#{config[:nick_id]}|#{config[:nick]}|#{msg}~~~"
          }
        else  
          if Thread.current[:on_thread]
            client.message(channel: im["channel"]["id"], as_user: true, text: msg, thread_ts: Thread.current[:thread_ts])
          else
            client.message(channel: im["channel"]["id"], as_user: true, text: msg)
          end
        end
        if config[:testing] and config.on_master_bot
          open("#{config.path}/buffer.log", "a") { |f|
            f.puts "|#{im["channel"]["id"]}|#{config[:nick_id]}|#{config[:nick]}|#{msg}"
          }
        end
      end
    end
  end

end
