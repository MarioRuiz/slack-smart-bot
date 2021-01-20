class SlackSmartBot

  def build_help(path, expanded)
    help_message = {}
    Dir["#{path}/*"].each do |t|
      if Dir.exist?(t)
        help_message[t.scan(/\/(\w+)$/).join.to_sym] = build_help(t, expanded)
      else
        if expanded
          help_message[t.scan(/\/(\w+)\.rb$/).join.to_sym] = IO.readlines(t).join.scan(/#\s*help\s*\w*:(.*)/).join("\n")
        else
          res = IO.readlines(t).join.scan(/#\s*help\s*\w*:(.*)/).join("\n")
          resf = ""
          command_done = false
          explanation_done = false
          example_done = false
          
          res.split("\n").each do |line|
            if line.match?(/^\s*\-+\s*/i)
              resf += line
            elsif !command_done and line.match?(/^\s*`.+`\s*/i)
              resf += "\n#{line}"
              command_done = true
            elsif !explanation_done and line.match?(/^\s+[^`].+\s*/i)
              resf += "\n#{line}"
              explanation_done = true
            elsif !example_done and line.match?(/^\s*_.+_\s*/i)
              resf += "\n     Example: #{line}"
              example_done = true
            end
          end
          resf += "\n\n"
          help_message[t.scan(/\/(\w+)\.rb$/).join.to_sym] = resf
        end
      end
    end
    return help_message
  end

end
