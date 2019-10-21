class SlackSmartBot
  def respond(msg, dest = nil)
    if dest.nil? and Thread.current.key?(:dest)
      dest = Thread.current[:dest]
    end
    dest = @channels_id[dest] if @channels_id.key?(dest) #it is a name of channel

    if dest.nil?
      client.message(channel: @channel_id, text: msg, as_user: true)
      if config[:testing] and ON_MASTER_BOT
        open("./buffer.log", "a") { |f|
          f.puts "|#{@channel_id}|#{config[:nick_id]}|#{msg}"
        }
      end
    elsif dest[0] == "C" or dest[0] == "G" # channel
      client.message(channel: dest, text: msg, as_user: true)
      if config[:testing] and ON_MASTER_BOT
        open("./buffer.log", "a") { |f|
          f.puts "|#{dest}|#{config[:nick_id]}|#{msg}"
        }
      end
    elsif dest[0] == "D" or dest[0] == "U" # Direct message
      send_msg_user(dest, msg)
    elsif dest[0] == "@"
      begin
        user_info = client.web_client.users_info(user: dest)
        send_msg_user(user_info.user.id, msg)
      rescue Exception => stack
        @logger.warn("user #{dest} not found.")
        @logger.warn stack
        if Thread.current.key?(:dest)
          respond("User #{dest} not found.")
        end
      end
    else
      @logger.warn("method respond not treated correctly: msg:#{msg} dest:#{dest}")
    end
  end

  def respond_direct(msg)
    dest = Thread.current[:user].id
    respond(msg, dest)
  end

  #context: previous message
  #to: user that should answer
  def ask(question, context = nil, to = nil, dest = nil)
    if dest.nil? and Thread.current.key?(:dest)
      dest = Thread.current[:dest]
    end
    if to.nil?
      to = Thread.current[:user].name
    end
    if context.nil?
      context = Thread.current[:command]
    end
    message = "#{to}: #{question}"
    if dest.nil?
      client.message(channel: @channel_id, text: message, as_user: true)
      if config[:testing] and ON_MASTER_BOT
        open("./buffer.log", "a") { |f|
          f.puts "|#{@channel_id}|#{config[:nick_id]}|#{message}"
        }
      end
    elsif dest[0] == "C" or dest[0] == "G" # channel
      client.message(channel: dest, text: message, as_user: true)
      if config[:testing] and ON_MASTER_BOT
        open("./buffer.log", "a") { |f|
          f.puts "|#{dest}|#{config[:nick_id]}|#{message}"
        }
      end
    elsif dest[0] == "D" #private message
      send_msg_user(dest, message)
    end
    @questions[to] = context
  end

  # to: (String) Channel name or id
  # msg: (String) message to send
  def send_msg_channel(to, msg)
    unless msg == ""
      get_channels_name_and_id() unless @channels_name.key?(to) or @channels_id.key?(to)
      if @channels_name.key?(to) #it is an id
        channel_id = to
      elsif @channels_id.key?(to) #it is a channel name
        channel_id = @channels_id[to]
      else
        @logger.fatal "Channel: #{to} not found. Message: #{msg}"
      end
      client.message(channel: channel_id, text: msg, as_user: true)
      if config[:testing] and ON_MASTER_BOT
        open("./buffer.log", "a") { |f|
          f.puts "|#{to}|#{config[:nick_id]}|#{msg}"
        }
      end
    end
  end

  #to send messages without listening for a response to users
  def send_msg_user(id_user, msg)
    unless msg == ""
      if id_user[0] == "D"
        client.message(channel: id_user, as_user: true, text: msg)
        if config[:testing] and ON_MASTER_BOT
          open("./buffer.log", "a") { |f|
            f.puts "|#{id_user}|#{config[:nick_id]}|#{msg}"
          }
        end
      else
        im = client.web_client.im_open(user: id_user)
        client.message(channel: im["channel"]["id"], as_user: true, text: msg)
        if config[:testing] and ON_MASTER_BOT
          open("./buffer.log", "a") { |f|
            f.puts "|#{im["channel"]["id"]}|#{config[:nick_id]}|#{msg}"
          }
        end
      end
    end
  end

  #to send a file to an user or channel
  #send_file(dest, 'the message', "#{project_folder}/temp/logs_ptBI.log", 'message to be sent', 'text/plain', "text")
  #send_file(dest, 'the message', "#{project_folder}/temp/example.jpeg", 'message to be sent', 'image/jpeg', "jpg")
  def send_file(to, msg, file, title, format, type = "text")
    if to[0] == "U" #user
      im = client.web_client.im_open(user: to)
      channel = im["channel"]["id"]
    else
      channel = to
    end

    client.web_client.files_upload(
      channels: channel,
      as_user: true,
      file: Faraday::UploadIO.new(file, format),
      title: title,
      filename: file,
      filetype: type,
      initial_comment: msg,
    )
  end

  def dont_understand(rules_file = nil, command = nil, user = nil, dest = nil, answer = ["what?", "huh?", "sorry?", "what do you mean?", "I don't understand"])
    if command.nil?
      command = Thread.current[:command]
    end
    if user.nil?
      user = Thread.current[:user]
    end
    if dest.nil?
      dest = Thread.current[:dest]
    end
    if rules_file.nil?
      rules_file = Thread.current[:rules_file]
    end

    if rules_file == ""
      res_final = []
    else
      text = get_help(rules_file, dest, user.name)

      ff = text.scan(/\s*`\s*([^`]+)\s*`\s*/i).flatten
      ff.delete("!THE_COMMAND")
      ff.delete("@NAME_OF_BOT THE_COMMAND")
      ff.delete("NAME_OF_BOT THE_COMMAND")

      ff2 = {}
      acommand = command.split(/\s+/)
      ff.each do |f|
        ff2[f] = ""
        af = f.split(/\s+/)
        af.each_with_index do |word, i|
          if acommand.size >= (i - 1) and word.match?(/[A-Z_\-#@]+/)
            ff2[f] += "#{acommand[i]} "
          else
            ff2[f] += "#{word} "
          end
        end
        ff2[f].rstrip!
      end

      spell_checker = DidYouMean::SpellChecker.new(dictionary: ff2.values)
      res = spell_checker.correct(command).uniq
      res_final = []
      res.each do |r|
        res_final << (ff2.select { |k, v| v == r }).keys
      end
      res_final.flatten!
    end
    if res_final.empty?
      resp = answer.sample
      respond "#{user.profile.display_name}, #{resp}", dest
    else
      respond "#{user.profile.display_name}, I don't understand. Maybe you are trying to say:\n`#{res_final[0..4].join("`\n`")}`", dest
    end
  end
end
