class ContextRetrievalService
  STOP_WORDS = %w[
    the a an is are was were be been being have has had do does did
    will would could should may might must shall can this that these
    those i you he she it we they what which who whom whose where
    when why how all each every both few more most other some such
    no nor not only own same so than too very just but and or if
    because as until while of at by for with about against between
    into through during before after above below to from up down in
    out on off over under again further then once here there when
    where why how any
  ].freeze

  attr_reader :leaf, :book, :query

  def initialize(leaf, query: nil)
    @leaf = leaf
    @book = leaf.book
    @query = query || leaf.searchable_content
  end

  def retrieve(limit: 5)
    return [] if query.blank?

    keyword_search(limit)
  end

  def retrieve_with_context(limit: 5)
    related = retrieve(limit: limit)
    return [] if related.empty?

    related.map do |related_leaf|
      {
        id: related_leaf.id,
        title: related_leaf.title,
        type: related_leaf.leafable_type,
        content: related_leaf.searchable_content&.truncate(1000),
        relevance: related_leaf.try(:relevance_score)
      }
    end
  end

  private

  def keyword_search(limit)
    key_terms = extract_key_terms(query)
    return [] if key_terms.empty?

    search_query = build_fts_query(key_terms)

    # Use with_search_results_for directly to avoid the extra SELECT columns
    # that conflict with count operations
    book.leaves
        .active
        .where.not(id: leaf.id)
        .with_search_results_for(search_query)
        .favoring_title
        .limit(limit)
        .to_a
  end

  def extract_key_terms(text, max_terms: 10)
    return [] if text.blank?

    words = text.downcase.scan(/[a-z]+/)

    words = words.reject { |w| w.length < 3 }

    words = words - STOP_WORDS

    word_counts = words.tally
    word_counts
      .sort_by { |_, count| -count }
      .first(max_terms)
      .map(&:first)
  end

  def build_fts_query(terms)
    terms.map { |term| "\"#{term}\"" }.join(" OR ")
  end
end
