class SlackSmartBot
  def see_command_ids()
    save_stats(__method__)
    commands = Dir.entries("#{__dir__}/../general/").select{|e| e.match?(/\.rb/)}
    respond "*General Commands*: #{commands.sort.join(' / ').gsub('.rb','')}"

    commands = Dir.entries("#{__dir__}/../on_bot/general/").select{|e| e.match?(/\.rb/)}
    respond "*On Bot general*: #{commands.sort.join(' / ').gsub('.rb','')}"

    commands = Dir.entries("#{__dir__}/../on_bot/").select{|e| e.match?(/\.rb/)}
    respond "*On Bot on demand*: #{commands.sort.join(' / ').gsub('.rb','')}"

    commands = Dir.entries("#{__dir__}/../on_bot/admin/").select{|e| e.match?(/\.rb/)}
    respond "*On Bot admin*: #{commands.sort.join(' / ').gsub('.rb','')}"
    
    commands = Dir.entries("#{__dir__}/../on_bot/admin_master/").select{|e| e.match?(/\.rb/)}
    respond "*On Bot master admin*: #{commands.sort.join(' / ').gsub('.rb','')}"

    commands = Dir.entries("#{__dir__}/../on_extended/").select{|e| e.match?(/\.rb/)}
    respond "*On extended*: #{commands.sort.join(' / ').gsub('.rb','')}"

    commands = Dir.entries("#{__dir__}/../on_master/").select{|e| e.match?(/\.rb/)}
    respond "*On Master*: #{commands.sort.join(' / ').gsub('.rb','')}"

    commands = Dir.entries("#{__dir__}/../on_master/admin/").select{|e| e.match?(/\.rb/)}
    respond "*On Master admin*: #{commands.sort.join(' / ').gsub('.rb','')}"
    
    commands = Dir.entries("#{__dir__}/../on_master/admin_master/").select{|e| e.match?(/\.rb/)}
    respond "*On Master master admin*: #{commands.sort.join(' / ').gsub('.rb','')}"

  end
end