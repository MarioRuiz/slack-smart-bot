class SlackSmartBot
  # help: ----------------------------------------------
  # help: `ruby RUBY_CODE`
  # help: `code RUBY_CODE`
  # help:     runs the code supplied and returns the output. Also you can send a Ruby file instead. Examples:
  # help:       _code puts (34344/99)*(34+14)_
  # help:       _ruby require 'json'; res=[]; 20.times {res<<rand(100)}; my_json={result: res}; puts my_json.to_json_
  # help:

  def ruby_code(dest, code, rules_file)
    save_stats(__method__)
    unless code.match?(/System/i) or code.match?(/Kernel/i) or code.include?("File") or
           code.include?("`") or code.include?("exec") or code.include?("spawn") or code.include?("IO.") or
           code.match?(/open3/i) or code.match?(/bundle/i) or code.match?(/gemfile/i) or code.include?("%x") or
           code.include?("ENV") or code.match?(/=\s*IO/)
      unless rules_file.empty?
        begin
          eval(File.new(config.path+rules_file).read) if File.exist?(config.path+rules_file)
        end
      end

      respond "Running", dest if code.size > 100

      begin
        code.gsub!(/^\W*$/, "") #to remove special chars from slack when copy/pasting
        ruby = "ruby -e \"#{code.gsub('"', '\"')}\""
        if defined?(project_folder) and project_folder.to_s != "" and Dir.exist?(project_folder)
          ruby = ("cd #{project_folder} &&" + ruby)
        else
          def project_folder() "" end
        end
        stdout, stderr, status = Open3.capture3(ruby)
        if stderr == ""
          if stdout == ""
            respond "Nothing returned. Remember you need to use p or puts to print", dest
          else
            respond stdout, dest
          end
        else
          respond "#{stderr}\n#{stdout}", dest
        end
      rescue Exception => exc
        respond exc, dest
      end
    else
      respond "Sorry I cannot run this due security reasons", dest
    end
  end
end
