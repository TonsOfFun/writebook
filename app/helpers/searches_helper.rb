module SearchesHelper
  def highlight_searched_content(leaf, content, query)
    if query.present?
      terms = leaf.matches_for_highlight(query)
      terms = whole_word_matchers(terms)

      sanitize_content highlight(content, terms, sanitize: false)
    else
      content
    end
  end

  private
    def whole_word_matchers(terms)
      terms.map { |term| /\b#{term}\b/ }
    end
end
