class SlackSmartBot
  def get_smartbot_team_info(token=nil)
    token = config.token if token.nil?
    client_web = Slack::Web::Client.new(token: token)
    client_web.auth_test
    resp = client_web.team_info
    client_web = nil
    return resp
  end
end
