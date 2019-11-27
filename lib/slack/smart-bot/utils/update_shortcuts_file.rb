class SlackSmartBot
  def update_shortcuts_file
    file = File.open("#{config.path}/shortcuts/#{config.shortcuts_file}", "w")
    file.write @shortcuts.inspect
    file.close
  end
end
