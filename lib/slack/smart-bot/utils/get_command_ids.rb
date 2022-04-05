class SlackSmartBot
  def get_command_ids
    commands = {
      general: [],
      on_bot_general: [],
      on_bot_on_demand: [],
      on_bot_admin: [],
      on_bot_master_admin: [],
      on_extended: [],
      on_master: [],
      on_master_admin: [],
      on_master_master_admin: [],
      general_commands: [],
      general_rules: [],
      rules: []
    }
    typem = Thread.current[:typem]
    user = Thread.current[:user]
    # :on_call, :on_bot, :on_extended, :on_dm, :on_master, :on_pg, :on_pub
    admin = is_admin?(user.name)

    commands[:general] = (Dir.entries("#{__dir__}/../commands/general/").select { |e| e.match?(/\.rb/) }).sort.join('|').gsub('.rb','').split('|')
    general = File.read("#{__dir__}/../commands/general_bot_commands.rb")
    commands[:general] += general.scan(/^\s*#\s*help\w*:\s+command_id:\s+:(\w+)\s*$/i).flatten
    commands[:general].uniq!
    
    if typem == :on_bot or typem == :on_master
      commands[:on_bot_general] = (Dir.entries("#{__dir__}/../commands/on_bot/general/").select { |e| e.match?(/\.rb/) }).sort.join('|').gsub('.rb','').split('|')
    end

    if typem == :on_bot or typem == :on_master
      commands[:on_bot_on_demand] = (Dir.entries("#{__dir__}/../commands/on_bot/").select { |e| e.match?(/\.rb/) }).sort.join('|').gsub('.rb','').split('|')
    end

    if (typem == :on_bot or typem == :on_master) and admin
      commands[:on_bot_admin] = (Dir.entries("#{__dir__}/../commands/on_bot/admin/").select { |e| e.match?(/\.rb/) }).sort.join('|').gsub('.rb','').split('|')
    end

    if (typem == :on_bot or typem == :on_master) and config.masters.include?(user.name)
      commands[:on_bot_master_admin] = (Dir.entries("#{__dir__}/../commands/on_bot/admin_master/").select { |e| e.match?(/\.rb/) }).sort.join('|').gsub('.rb','').split('|')
    end

    if typem == :on_extended
      commands[:on_extended] = (Dir.entries("#{__dir__}/../commands/on_extended/").select { |e| e.match?(/\.rb/) }).sort.join('|').gsub('.rb','').split('|')
      commands[:on_extended]+= ['repl', 'see_repls', 'get_repl', 'run_repl', 'delete_repl', 'ruby_code']
    end

    if typem == :on_master
      commands[:on_master] = (Dir.entries("#{__dir__}/../commands/on_master/").select { |e| e.match?(/\.rb/) }).sort.join('|').gsub('.rb','').split('|')
    end

    if typem == :on_master and admin
      commands[:on_master_admin] = (Dir.entries("#{__dir__}/../commands/on_master/admin/").select { |e| e.match?(/\.rb/) }).sort.join('|').gsub('.rb','').split('|')
    end

    if typem == :on_master and config.masters.include?(user.name)
      commands[:on_master_master_admin] = (Dir.entries("#{__dir__}/../commands/on_master/admin_master/").select { |e| e.match?(/\.rb/) }).sort.join('|').gsub('.rb','').split('|')
    end

    if File.exists?("#{config.path}/rules/general_commands.rb")
      general_commands = File.read("#{config.path}/rules/general_commands.rb")
      commands[:general_commands] = general_commands.scan(/^\s*#\s*help\w*:\s+command_id:\s+:(\w+)\s*$/i).flatten
      commands[:general_commands]+= general_commands.scan(/^\s*save_stats\(?\s*:(\w+)\s*,?/i).flatten
      commands[:general_commands].uniq!
    end

    if typem == :on_extended or typem ==:on_call or typem == :on_bot or typem == :on_master or (typem == :on_dm and Thread.current[:using_channel].to_s != '')
      if Thread.current.key?(:rules_file) and File.exists?(config.path + Thread.current[:rules_file])
        rules = File.read(config.path + Thread.current[:rules_file])
        commands[:rules] = rules.scan(/^\s*#\s*help\w*:\s+command_id:\s+:(\w+)\s*$/i).flatten
        commands[:rules]+= rules.scan(/^\s*save_stats\(?\s*:(\w+)\s*,?/i).flatten
        commands[:rules].uniq!

        if File.exists?("#{config.path}/rules/general_rules.rb")
          general_rules = File.read("#{config.path}/rules/general_rules.rb")
          commands[:general_rules] = general_rules.scan(/^\s*#\s*help\w*:\s+command_id:\s+:(\w+)\s*$/i).flatten
          commands[:general_rules]+= general_rules.scan(/^\s*save_stats\(?\s*:(\w+)\s*,?/i).flatten
          commands[:general_rules].uniq!  
        end
      end
    end
    return commands
  end
end
