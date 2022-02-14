class SlackSmartBot
  def update_shortcuts_file
    require 'yaml'
    sc_file = "#{config.path}/shortcuts/#{config.shortcuts_file}"
    File.open(sc_file, 'w') {|file|
      file.flock(File::LOCK_EX)
      file.write(@shortcuts.to_yaml) 
      file.flock(File::LOCK_UN)
    }

    if config.on_master_bot
      sc_file = "#{config.path}/shortcuts/shortcuts_global.yaml"
      File.open(sc_file, 'w') {|file|
        file.flock(File::LOCK_EX)
        file.write(@shortcuts_global.to_yaml) 
        file.flock(File::LOCK_UN)
      }
    end
  end
end
