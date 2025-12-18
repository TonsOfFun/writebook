module Leaf::Contextable
  extend ActiveSupport::Concern

  def related_leaves(limit: 5, query: nil)
    ContextRetrievalService.new(self, query: query).retrieve(limit: limit)
  end

  def related_context(limit: 5, query: nil)
    ContextRetrievalService.new(self, query: query).retrieve_with_context(limit: limit)
  end

  def context_for_llm(limit: 3, query: nil)
    related = related_context(limit: limit, query: query)
    return nil if related.empty?

    sections = related.map do |ctx|
      "### #{ctx[:title]}\n#{ctx[:content]}"
    end

    sections.join("\n\n---\n\n")
  end
end
