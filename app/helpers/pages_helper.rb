module PagesHelper
  def word_count(content)
    return if content.blank?
    pluralize number_with_delimiter(content.split.size), "word"
  end

  def page_title(leaf, book)
    [ leaf.title, book.title, book.author ].reject(&:blank?).to_sentence(two_words_connector: " · ", words_connector: " · ", last_word_connector: " · ")
  end

  def sanitize_content(content)
    sanitize content, scrubber: HtmlScrubber.new
  end
end
