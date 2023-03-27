class SlackSmartBot
  def respond_thread(msg='', unfurl_links: true, unfurl_media: true, blocks: [])
    respond(msg, :on_thread, unfurl_links: unfurl_links, unfurl_media: unfurl_media, blocks: blocks)
  end
end
