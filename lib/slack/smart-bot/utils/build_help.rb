class SlackSmartBot

  def build_help(path)
    help_message = {}
    Dir["#{path}/*"].each do |t|
      if Dir.exist?(t)
        help_message[t.scan(/\/(\w+)$/).join.to_sym] = build_help(t)
      else
        help_message[t.scan(/\/(\w+)\.rb$/).join.to_sym] = IO.readlines(t).join.scan(/#\s*help\s*\w*:(.*)/).join("\n")
      end
    end
    return help_message
  end

end
