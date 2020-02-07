class SlackSmartBot

  #to send a file to an user or channel
  #send_file(dest, 'the message', "#{project_folder}/temp/logs_ptBI.log", 'message to be sent', 'text/plain', "text")
  #send_file(dest, 'the message', "#{project_folder}/temp/example.jpeg", 'message to be sent', 'image/jpeg', "jpg")
  def send_file(to, msg, file, title, format, type = "text")
    unless config[:simulate]
      if to[0] == "U" #user
        im = client.web_client.im_open(user: to)
        channel = im["channel"]["id"]
      else
        channel = to
      end

      if Thread.current[:on_thread]
        ts = Thread.current[:thread_ts]
      else
        ts = nil
      end

      client.web_client.files_upload(
        channels: channel,
        as_user: true,
        file: Faraday::UploadIO.new(file, format),
        title: title,
        filename: file,
        filetype: type,
        initial_comment: msg,
        thread_ts: ts
      )
    end
  end

end
