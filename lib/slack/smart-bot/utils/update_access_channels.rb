class SlackSmartBot

  def update_access_channels()
    file = File.open("#{config.path}/rules/#{@channel_id}/access_channels.rb", "w")
    file.write (@access_channels.inspect)
    file.close
  end
end
