class SlackSmartBot
  def see_command_ids()
    save_stats(__method__)
    commands = get_command_ids()

    respond "*General Commands*: #{(commands[:general]+commands[:general_commands]).sort.join(' / ')}" unless commands[:general].empty?

    respond "*On Bot general*: #{commands[:on_bot_general].sort.join(' / ')}" unless commands[:on_bot_general].empty?

    respond "*On Bot on demand*: #{commands[:on_bot_on_demand].sort.join(' / ')}" unless commands[:on_bot_on_demand].empty?

    respond "*On Bot admin*: #{commands[:on_bot_admin].sort.join(' / ')}" unless commands[:on_bot_admin].empty?
    
    respond "*On Bot master admin*: #{commands[:on_bot_master_admin].sort.join(' / ')}" unless commands[:on_bot_master_admin].empty?

    respond "*On extended*: #{commands[:on_extended].sort.join(' / ')}" unless commands[:on_extended].empty?

    respond "*On Master*: #{commands[:on_master].sort.join(' / ')}" unless commands[:on_master].empty?

    respond "*On Master admin*: #{commands[:on_master_admin].sort.join(' / ')}" unless commands[:on_master_admin].empty?
    
    respond "*On Master master admin*: #{commands[:on_master_master_admin].sort.join(' / ')}" unless commands[:on_master_master_admin].empty?

    respond "*General Rules*: #{commands[:general_rules].sort.join(' / ')}" unless commands[:general_rules].empty?

    respond "*Rules*: #{commands[:rules].sort.join(' / ')}" unless commands[:rules].empty?

  end
end