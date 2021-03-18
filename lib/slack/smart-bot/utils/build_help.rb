class SlackSmartBot

  def build_help(path, expanded)
    help_message = {normal: {}, admin: {}, master: {}}
    if Dir.exist?(path)
      files = Dir["#{path}/*"]
    elsif File.exist?(path)
      files = [path]
    else
      return help_message
    end

    files.each do |t|
      if Dir.exist?(t)
        res = build_help(t, expanded)
        help_message[:master][t.scan(/\/(\w+)$/).join.to_sym] = res[:master]
        help_message[:admin][t.scan(/\/(\w+)$/).join.to_sym] = res[:admin]
        help_message[:normal][t.scan(/\/(\w+)$/).join.to_sym] = res[:normal]
      else
        lines = IO.readlines(t)
        data = {master:{}, admin:{}, normal:{}}
        data.master = lines.join #normal user help
        data.admin = lines.reject {|l| l.match?(/^\s*#\s*help\s*master\s*:.+$/i)}.join #not master help
        data.normal = lines.reject {|l| l.match?(/^\s*#\s*help\s*(admin|master)\s*:.+$/i)}.join #not admin or master help
        if expanded
          help_message[:master][t.scan(/\/(\w+)\.rb$/).join.to_sym] = data.master.scan(/#\s*help\s*\w*:(.*)/i).join("\n")
          help_message[:admin][t.scan(/\/(\w+)\.rb$/).join.to_sym] = data.admin.scan(/#\s*help\s*\w*:(.*)/i).join("\n")
          help_message[:normal][t.scan(/\/(\w+)\.rb$/).join.to_sym] = data.normal.scan(/#\s*help\s*\w*:(.*)/i).join("\n") 
        else
          data.keys.each do |key|
            res = data[key].scan(/#\s*help\s*\w*:(.*)/i).join("\n")
            resf = ""
            command_done = false
            explanation_done = false
            example_done = false
            
            res.split("\n").each do |line|
              if line.match?(/^\s*======+$/)
                command_done = true
                explanation_done = true
                example_done = true
              elsif line.match?(/^\s*\-\-\-\-+\s*$/i)
                resf += "\n#{line}"
                command_done = false
                explanation_done = false
                example_done = false
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
            help_message[key][t.scan(/\/(\w+)\.rb$/).join.to_sym] = resf
          end
        end
      end
    end
    return help_message
  end

end
