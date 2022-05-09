class SlackSmartBot

  def get_channels_name_and_id
    @channels_list = get_channels()
    @channels_id = Hash.new()
    @channels_name = Hash.new()
    @channels_creator = Hash.new()
    @users = get_users() if @users.empty?
    @channels_list.each do |ch|
      unless ch.is_archived
        @channels_id[ch.name] = ch.id
        @channels_name[ch.id] = ch.name
        user_info = @users.select{|u| u.id == ch.creator or (u.key?(:enterprise_user) and u.enterprise_user.id == ch.creator)}[-1]
        @channels_creator[ch.id] = user_info.name unless user_info.nil?
        @channels_creator[ch.name] = user_info.name unless user_info.nil?
      end
    end
  end

end
