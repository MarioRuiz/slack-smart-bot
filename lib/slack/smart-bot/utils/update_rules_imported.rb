class SlackSmartBot

  def update_rules_imported
    file = File.open("#{config.path}/rules/rules_imported.rb", "w")
    file.write @rules_imported.inspect
    file.close
  end
end
