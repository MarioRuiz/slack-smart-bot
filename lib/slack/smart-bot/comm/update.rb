class SlackSmartBot
  def update(channel, ts, text)
    result = true
    begin
      resp = client.web_client.chat_update(channel: channel, as_user: true, ts: ts, text: text)
      result = resp.ok.to_s == 'true'
    rescue Exception => exc
      result = false
      @logger.fatal exc.inspect
    end
    return result
  end
end
