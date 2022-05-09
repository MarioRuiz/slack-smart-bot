class SlackSmartBot
  # help: ----------------------------------------------
  # help: `ruby RUBY_CODE`
  # help: `code RUBY_CODE`
  # help:     runs the code supplied and returns the output. Also you can send a Ruby file instead. Examples:
  # help:       _code puts (34344/99)*(34+14)_
  # help:       _ruby require 'json'; res=[]; 20.times {res<<rand(100)}; my_json={result: res}; puts my_json.to_json_
  # help:     <https://github.com/MarioRuiz/slack-smart-bot#running-ruby-code-on-a-conversation|more info>
  # help: command_id: :ruby_code
  # help:

  def ruby_code(dest, user, code, rules_file)
    save_stats(__method__)
    if has_access?(__method__, user)
      unless code.match?(/System/i) or code.match?(/Kernel/i) or code.include?("File.") or
            code.include?("`") or code.include?("exec") or code.include?("spawn") or code.include?("IO.") or
            code.match?(/open3/i) or code.match?(/bundle/i) or code.match?(/gemfile/i) or code.include?("%x") or
            code.include?("ENV") or code.match?(/=\s*IO/) or code.include?("Dir.") or code.match?(/=\s*IO/) or
            code.match?(/=\s*File/) or code.match?(/=\s*Dir/) or code.match?(/<\s*File/) or code.match?(/<\s*Dir/) or
            code.match?(/\w+:\s*File/) or code.match?(/\w+:\s*Dir/)
        react :running
        unless rules_file.empty?
          begin
            eval(File.new(config.path+rules_file).read) if File.exist?(config.path+rules_file)
          end
        end

        respond "Running", dest if code.size > 200

        begin
          code.gsub!(/^\W*$/, "") #to remove special chars from slack when copy/pasting
          code.gsub!('$','\$') #to take $ as literal, fex: puts '$lolo' => puts '\$lolo'
          ruby = "ruby -e \"#{code.gsub('"', '\"')}\""
          if defined?(project_folder) and project_folder.to_s != "" and Dir.exist?(project_folder)
            ruby = ("cd #{project_folder} &&" + ruby)
          else
            def project_folder() "" end
          end

          stdin, stdout, stderr, wait_thr = Open3.popen3(ruby)
          timeout = timeoutt = 20
          procstart = Time.now
          while (wait_thr.status == 'run' or wait_thr.status == 'sleep') and timeout > 0
            timeout -= 0.1
            sleep 0.1
          end
          if timeout > 0
            stdout = stdout.read
            stderr = stderr.read
            if stderr == ""
              if stdout == ""
                respond "Nothing returned. Remember you need to use p or puts to print", dest
              else
                respond stdout, dest
              end
            else
              respond "#{stderr}\n#{stdout}", dest
            end
          else
            respond "The process didn't finish in #{timeoutt} secs so it was aborted. Timeout!"
            pids = `pgrep -P #{wait_thr.pid}`.split("\n").map(&:to_i) #todo: it needs to be adapted for Windows
            pids.each do |pid|
              begin
                Process.kill("KILL", pid)
              rescue
              end
            end
          end
        rescue Exception => exc
          respond exc, dest
        end
        unreact :running
      else
        respond "Sorry I cannot run this due security reasons", dest
      end
    end
  end
end
