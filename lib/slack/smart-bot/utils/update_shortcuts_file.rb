class SlackSmartBot
  def update_shortcuts_file
    file = File.open("#{config.path}/shortcuts/#{config.shortcuts_file}", "w")
    file.write @shortcuts.inspect
    file.close

    if config.on_master_bot
      file = File.open("#{config.path}/shortcuts/shortcuts_global.rb", "w")
      file.write @shortcuts_global.inspect
      file.close
    end
  end
end
