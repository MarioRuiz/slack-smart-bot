class SlackSmartBot
  def get_keywords(sentence, list_avoid: [])
    require "engtagger"
    keywords = []
    unless sentence.to_s.strip.empty?
      # Initialize the POS tagger
      tagger = EngTagger.new
      tagged_sentence = tagger.add_tags(sentence)
      unless tagged_sentence.nil?

        # Extract nouns and proper nouns from the sentence
        nouns = tagger.get_nouns(tagged_sentence).keys
        proper_nouns = tagger.get_proper_nouns(tagged_sentence).keys
        adjectives = tagger.get_adjectives(tagged_sentence).keys
        ids = sentence.scan(/([\w]+\-[\w\-]+)/)

        # Combine nouns and proper nouns to create the list of keywords
        keywords = (nouns + proper_nouns + adjectives + ids.flatten).uniq

        #delete all keywords that are one or two characters long
        keywords.delete_if { |keyword| keyword.length < 3 }
        # delete all keywords that are in the list_avoid /word/i
        if !list_avoid.empty?
          keywords.delete_if { |keyword| list_avoid.any? { |avoid| keyword.match?(/#{avoid}/i) } }
        end

        #remove special characters from the keywords
        keywords.map! { |keyword| keyword.gsub(/[^\w\-_]/i, "") }
      end
    end
    return keywords
  end
end
