class SlackSmartBot

  def get_channels_name_and_id
    channels = get_channels()
    @channels_id = Hash.new()
    @channels_name = Hash.new()
    channels.each do |ch|
      unless ch.is_archived
        @channels_id[ch.name] = ch.id
        @channels_name[ch.id] = ch.name
      end
    end
  end

end
