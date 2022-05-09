class SlackSmartBot

  def update_admins_channels()
    file = File.open("#{config.path}/rules/#{@channel_id}/admins_channels.rb", "w")
    file.write (@admins_channels.inspect)
    file.close
  end
end
