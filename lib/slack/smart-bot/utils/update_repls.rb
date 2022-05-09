class SlackSmartBot
  def update_repls(channel = @channel_id)
    require 'yaml'
    repl_file = "#{config.path}/repl/repls_#{channel}.yaml"
    File.open(repl_file, 'w') {|file|
      file.flock(File::LOCK_EX)
      file.write(@repls.to_yaml) 
      file.flock(File::LOCK_UN)
    }
  end
end
