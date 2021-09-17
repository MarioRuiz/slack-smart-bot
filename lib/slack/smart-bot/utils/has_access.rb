class SlackSmartBot
    def has_access?(method, user=nil)
        user = Thread.current[:user] if user.nil?
        if config[:allow_access].key?(method) and !config[:allow_access][method].include?(user.name) and !config[:allow_access][method].include?(user.id) and 
            (!user.key?(:enterprise_user) or ( user.key?(:enterprise_user) and !config[:allow_access][method].include?(user[:enterprise_user].id)))
            respond "You don't have access to use this command, please contact an Admin to be able to use it: <@#{config.admins.join(">, <@")}>"
            return false
        else
            return true
        end      
    end
end