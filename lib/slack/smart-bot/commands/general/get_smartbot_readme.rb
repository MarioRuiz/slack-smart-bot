class SlackSmartBot
  #todo: Add tests
  def get_smartbot_readme(dest)
    save_stats(__method__)
    dir = Gem::Specification.latest_spec_for('slack-smart-bot').gem_dir
    file_name = "README.md"
    content = File.read("#{dir}/#{file_name}")
    content.gsub!('"img/', '"https://raw.githubusercontent.com/MarioRuiz/slack-smart-bot/master/img/')
    if File.exist?("#{dir}/#{file_name}")
      send_file(dest, "SmartBot README", "", file_name, "text/markdown", "markdown", content: content)
    else
      respond "There is no README.md"
    end
  end
end
