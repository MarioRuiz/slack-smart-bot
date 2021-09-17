class SlackSmartBot
  def respond_direct(msg, unfurl_links: true, unfurl_media: true)
    respond(msg, :direct, unfurl_links: unfurl_links, unfurl_media: unfurl_media)
  end
end
