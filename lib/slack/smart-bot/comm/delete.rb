class SlackSmartBot
  def delete(channel, ts)
    result = true
    begin
      resp = client.web_client.chat_delete(channel: channel, as_user: true, ts: ts)
      result = resp.ok.to_s == 'true'
    rescue Exception => exc
      result = false
      @logger.fatal exc.inspect
    end
    return result
  end
end
