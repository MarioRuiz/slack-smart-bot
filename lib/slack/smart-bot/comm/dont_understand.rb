class SlackSmartBot
  def dont_understand(rules_file = nil, command = nil, user = nil, dest = nil, answer = ["what?", "huh?", "sorry?", "what do you mean?", "I don't understand"], channel_rules: config.channel, typem: nil)
    save_stats(:dont_understand)
    command = Thread.current[:command] if command.nil?
    user = Thread.current[:user] if user.nil?
    dest = Thread.current[:dest] if dest.nil?
    rules_file = Thread.current[:rules_file] if rules_file.nil?
    typem = Thread.current[:typem] if typem.nil?
    if typem == :on_extended
      get_bots_created()
    end
    text = get_help(rules_file, dest, user, typem == :on_extended, true)

    ff = text.scan(/^\s*`\s*([^`]+)\s*`\s*$/i).flatten
    ff.delete("!THE_COMMAND")
    ff.delete("@NAME_OF_BOT THE_COMMAND")
    ff.delete("NAME_OF_BOT THE_COMMAND")
    ff.delete("@BOT_NAME on #CHANNEL_NAME COMMAND")

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

    if typem == :on_extended
      if @extended_from[@channels_name[dest]].size == 1
        respond "#{user.profile.display_name}, I don't understand.", dest
      end
      unless res_final.empty?
        respond "Similar rules on : *#{channel_rules}*\n`#{res_final[0..4].join("`\n`")}`", dest
      end
    else
      message = ""
      message = "\nTake in consideration when on external calls, not all the commands are available." if typem == :on_call
      if res_final.empty?
        resp = answer.sample
        respond "#{user.profile.display_name}, #{resp}#{message}", dest
      else
        respond "#{user.profile.display_name}, I don't understand. Maybe you are trying to say:\n`#{res_final[0..4].join("`\n`")}`#{message}", dest
      end
    end

    ai_conn, message = SlackSmartBot::AI::OpenAI.connect({}, config, {}, service: :chat_gpt)
    if message.empty?
      react :speech_balloon
      chatgpt = ai_conn[Thread.current[:team_id_user]].chat_gpt
      model = chatgpt.smartbot_model if model.nil?
      prompt = "I sent this command to Slack SmartBot: `#{command}` and it seems that is wrong\n\n"
      prompt += "These are the available SmartBot commands:\n#{text}\n\n"
      prompt += "Please, can you suggest the command that I mean?\n"
      prompt += "Return just like 5 lines of text max. If you supply a command do it like this: `the command`"
      success, res = SlackSmartBot::AI::OpenAI.send_gpt_chat(chatgpt.client, model, prompt, chatgpt)
      if success
        response_message = "*ChatGPT*: Maybe you are trying to say:\n#{res.to_s.strip}\n\n"
        response_message += "Remember you can always ask for help by calling `bot help ?? YOUR QUESTION`."
        respond transform_to_slack_markdown(response_message), dest
      end
      unreact :speech_balloon
    end
  end
end
