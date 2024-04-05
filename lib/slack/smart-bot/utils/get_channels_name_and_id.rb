class SlackSmartBot

  def get_channels_name_and_id
    @channels_list = get_channels()
    @channels_id = Hash.new()
    @channels_name = Hash.new()
    @channels_creator = Hash.new()
    @channels_list.each do |ch|
      unless ch.is_archived
        @channels_id[ch.name] = ch.id
        @channels_name[ch.id] = ch.name
        user_info = find_user(ch.creator)
        @channels_creator[ch.id] = "#{user_info.team_id}_#{user_info.name}" unless user_info.nil?
        @channels_creator[ch.name] = "#{user_info.team_id}_#{user_info.name}" unless user_info.nil?
      end
    end
  end

end
