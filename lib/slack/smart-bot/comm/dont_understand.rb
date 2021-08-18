class SlackSmartBot

  def dont_understand(rules_file = nil, command = nil, user = nil, dest = nil, answer = ["what?", "huh?", "sorry?", "what do you mean?", "I don't understand"], channel_rules: config.channel, typem: nil)
    save_stats(:dont_understand)
    command = Thread.current[:command] if command.nil?
    user = Thread.current[:user] if user.nil?
    dest = Thread.current[:dest] if dest.nil?
    rules_file = Thread.current[:rules_file] if rules_file.nil?
    typem = Thread.current[:typem] if typem.nil?
    if typem==:on_extended
      get_bots_created()
    end
    text = get_help(rules_file, dest, user.name, typem==:on_extended, true)

    ff = text.scan(/\s*`\s*([^`]+)\s*`\s*/i).flatten
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

    if typem==:on_extended
      if @extended_from[@channels_name[dest]].size == 1
        respond "#{user.profile.display_name}, I don't understand.", dest
      end
      unless res_final.empty?
        respond "Similar rules on : *#{channel_rules}*\n`#{res_final[0..4].join("`\n`")}`", dest
      end
    else
      message = ''
      message = "\nTake in consideration when on external calls, not all the commands are available." if typem==:on_call
      if res_final.empty?
        resp = answer.sample
        respond "#{user.profile.display_name}, #{resp}#{message}", dest
      else
        respond "#{user.profile.display_name}, I don't understand. Maybe you are trying to say:\n`#{res_final[0..4].join("`\n`")}`#{message}", dest
      end
    end
  end
end
