class SlackSmartBot
  def transform_to_slack_markdown(markdown_text)
    # Regular expressions to match code blocks
    code_block_regex = /```(.*?)```/m

    # Extract code blocks to preserve them
    preserved_code_blocks = markdown_text.scan(code_block_regex).map(&:first)

    # Replace code blocks and inline code with placeholders
    code_block_placeholder_text = ""
    while markdown_text.include?(code_block_placeholder_text)
      code_block_placeholder_text = "CODE_BLOCK_PLACEHOLDER_#{"6:x".gen}"
    end
    transformed_text = markdown_text.gsub(code_block_regex, code_block_placeholder_text)

    # Transform general Markdown to Slack Markdown
    transformed_text.gsub!(/^\* (.*)$/, '• \1')        # Unordered list
    transformed_text.gsub!(/^\s*d+. (.*)$/, '\1.')    # Ordered list
    transformed_text.gsub!(/!\[(.*?)\]\((.*?)\)/, '\1') # Images to alt text
    transformed_text.gsub!(/\[(.*?)\]\((.*?)\)/, '<\2|\1>') # Links
    transformed_text.gsub!(/\*\*(.*?)\*\*/, '*\1*')    # Bold
    transformed_text.gsub!(/__(.*?)__/, '*\1*')       # Bold
    # delete any * character in any position if it is a header
    transformed_text.gsub!(/^\s*#+.*\*/) { |match| match.gsub("*", "") }
    # add for more than 4 # the same than for #### but one :black_small_square: per extra #
    transformed_text.gsub!(/^\s*####(#+) (.*)$/) { "\n" + "#{":black_small_square:" * ($1.length + 1)} *#{$2}*" }
    transformed_text.gsub!(/^\s*#### (.*)$/, "\n" + ':black_small_square: *\1*')       # Header level 4 to bold
    transformed_text.gsub!(/^\s*### (.*)$/, "\n" + ':small_orange_diamond: *\1*')       # Header level 3 to bold
    transformed_text.gsub!(/^\s*## (.*)$/, "\n" + ':small_blue_diamond: *\1*')        # Header level 2 to bold
    transformed_text.gsub!(/^\s*# (.*)$/, "\n" + ':small_red_triangle: *\1*')         # Header level 1 to bold

    # Reinsert preserved code blocks and inline code
    preserved_code_blocks.each { |block| transformed_text.sub!(code_block_placeholder_text, "```#{block}```") }
    return transformed_text
  end
end
