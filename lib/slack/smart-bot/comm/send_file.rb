class SlackSmartBot

  #to send a file to an user or channel
  #send_file(dest, 'the message', "#{project_folder}/temp/logs_ptBI.log", 'message to be sent', 'text/plain', "text")
  #send_file(dest, 'the message', "#{project_folder}/temp/example.jpeg", 'message to be sent', 'image/jpeg', "jpg")
  #send_file(dest, 'the message', "", 'message to be sent', 'text/plain', "ruby", content: "the content to be sent when no file supplied")
  #send_file(dest, 'the message', "myfile.rb", 'message to be sent', 'text/plain', "ruby", content: "the content to be sent when no file supplied")
  def send_file(to, msg, file, title, format, type = "text", content: '')
    unless config[:simulate]
      file = 'myfile' if file.to_s == '' and content!=''
      if to[0] == "U" or to[0] == "W" #user
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

      if content.to_s == ''
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
      else
        client.web_client.files_upload(
          channels: channel,
          as_user: true,
          content: content,
          title: title,
          filename: file,
          filetype: type,
          initial_comment: msg,
          thread_ts: ts
        )
      end
    end
  end

end
