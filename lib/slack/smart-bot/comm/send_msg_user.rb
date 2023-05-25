class SlackSmartBot

  #to send messages without listening for a response to users
  def send_msg_user(id_user, msg='', on_thread=nil, unfurl_links: true, unfurl_media: true, blocks: [], web_client: true, thread_ts: nil)
    resp = nil
    unless msg == "" and blocks.empty?
      begin
        on_thread = Thread.current[:on_thread] if on_thread.nil?
        thread_ts = Thread.current[:thread_ts] if thread_ts.to_s == ""
        web_client = true if !blocks.empty? or !unfurl_links or !unfurl_media
        if id_user[0] == "D"
          if config[:simulate]
            open("#{config.path}/buffer_complete.log", "a") { |f|
              f.puts "|#{id_user}|#{thread_ts}|#{config[:nick_id]}|#{config[:nick]}|#{msg}~~~"
            }
          else
            if web_client
              if on_thread
                resp = client.web_client.chat_postMessage(channel: id_user, text: msg, blocks: blocks, as_user: true, unfurl_links: unfurl_links, unfurl_media: unfurl_media, thread_ts: thread_ts)
              else
                resp = client.web_client.chat_postMessage(channel: id_user, text: msg, blocks: blocks, as_user: true, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
              end
            else
              if on_thread
                resp = client.message(channel: id_user, as_user: true, text: msg, thread_ts: thread_ts, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
              else
                resp = client.message(channel: id_user, as_user: true, text: msg, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
              end
            end
          end
          if config[:testing] and config.on_master_bot and !@buffered
            @buffered = true
            open("#{config.path}/buffer.log", "a") { |f|
              f.puts "|#{id_user}|#{thread_ts}|#{config[:nick_id]}|#{config[:nick]}|#{msg}#{blocks.join}"
            }
          end
        else
          if config[:simulate]
            open("#{config.path}/buffer_complete.log", "a") { |f|
              f.puts "|#{DIRECT[id_user.to_sym].ubot}|#{thread_ts}|#{config[:nick_id]}|#{config[:nick]}|#{msg}#{blocks.join}~~~"
            }
          else  
            im = client.web_client.conversations_open(users: id_user)
            if web_client
              if on_thread
                resp = client.web_client.chat_postMessage(channel: im["channel"]["id"], text: msg, blocks: blocks, as_user: true, unfurl_links: unfurl_links, unfurl_media: unfurl_media, thread_ts: thread_ts)
              else
                resp = client.web_client.chat_postMessage(channel: im["channel"]["id"], text: msg, blocks: blocks, as_user: true, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
              end
            else
              if on_thread
                resp = client.message(channel: im["channel"]["id"], as_user: true, text: msg, thread_ts: thread_ts, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
              else
                resp = client.message(channel: im["channel"]["id"], as_user: true, text: msg, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
              end
            end
          end
          if config[:testing] and config.on_master_bot and !@buffered
            @buffered = true
            open("#{config.path}/buffer.log", "a") { |f|
              f.puts "|#{im["channel"]["id"]}|#{thread_ts}|#{config[:nick_id]}|#{config[:nick]}|#{msg}#{blocks.join}"
            }
          end
        end
      rescue Exception => stack
        @logger.warn stack
      end
    end
    return resp
  end

end
