class SlackSmartBot

  # help: ----------------------------------------------
  # help: `suggest command`
  # help: `random command`
  # help: `command suggestion`
  # help: `suggest rule`
  # help: `random rule`
  # help: `rule suggestion`
  # help:    it will display the help content for a random command.
  # help:    if used 'rule' then it will display a random rule.
  # help:    if used 'command' it will show any kind of command or rule.
  # help: command_id: :suggest_command
  # help:
  def suggest_command(from, dest, dchannel, specific, rules_file)
    save_stats(__method__)
    dont_suggest = []
    help_message = get_help(rules_file, dest, from, specific, true, descriptions: false, only_normal_user: true)
    commands = help_message.gsub(/====+/,'-'*30).split(/^\s*-------*$/).flatten
    commands.reject!{|c| c.match?(/These are specific commands for this bot on this/i) || c.match?(/\A\s*\z/)}
    dont_suggest.each do |ds|
      commands.reject!{|c| c.match?(/:#{ds}\s*$/i)}
    end
    @last_suggested_commands ||= []
    @last_suggested_commands.shift if @last_suggested_commands.size >=5
    command = ''
    begin 
      command = commands.sample
    end until !@last_suggested_commands.include?(command) or commands.size <= 5
    @last_suggested_commands << command
    command.gsub!(/^\s*command_id:\s+:\w+\s*$/,'')
    message = "*Command suggestion*:\n#{command}"
    respond message, dest, unfurl_links: false, unfurl_media: false
  end

end