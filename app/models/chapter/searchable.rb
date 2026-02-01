module Chapter::Searchable
  extend ActiveSupport::Concern

  included do
    after_create_commit  :create_in_search_index,   if: :searchable?
    after_update_commit  :update_in_search_index,   if: :searchable?
    after_destroy_commit :remove_from_search_index, if: :searchable?

    scope :favoring_title, -> { order(Arel.sql("bm25(chapter_search_index, 2.0)")) }
  end

  class_methods do
    def reindex_all
      all.map &:reindex
    end

    def sanitize_query_syntax(terms)
      terms = terms.to_s
      terms = remove_invalid_search_characters(terms)
      terms = remove_unbalanced_quotes(terms)
      terms.presence
    end

    def search(terms)
      if terms = sanitize_query_syntax(terms)
        with_search_results_for(terms)
          .select(
            "chapters.*",
            "highlight(chapter_search_index, 0, '<mark>', '</mark>') as title_match",
            "snippet(chapter_search_index, 1, '<mark>', '</mark>', '...', 20) as content_match")
      else
        none
      end
    end

    def with_search_results_for(terms)
      joins("join chapter_search_index on chapters.id = chapter_search_index.rowid")
        .where("chapter_search_index match ?", terms)
    end
  end

  def reindex
    update_in_search_index if searchable?
  end

  def matches_for_highlight(terms)
    if terms = self.class.sanitize_query_syntax(terms)
      content = Chapter.with_search_results_for(terms)
        .where(id: id)
        .pick(Arel.sql("highlight(chapter_search_index, 1, '<mark>', '</mark>')"))

      content ? unique_matching_terms(content) : []
    end
  end

  private
    def searchable?
      searchable_content
    end

    def create_in_search_index
      execute_sql_with_binds "insert into chapter_search_index(rowid, title, content ) values (?, ?, ?)",
        id, title, searchable_content
    end

    def update_in_search_index
      transaction do
        updated = execute_sql_with_binds "update chapter_search_index set title = ?, content = ? where rowid = ?",
          title, searchable_content, id

        create_in_search_index unless updated
      end
    end

    def remove_from_search_index
      execute_sql_with_binds "delete from chapter_search_index where rowid = ?", id
    end

    def execute_sql_with_binds(*statement)
      self.class.connection.execute self.class.sanitize_sql(statement)

      self.class.connection.raw_connection.changes.nonzero?
    end

    def unique_matching_terms(content)
      terms = content.scan(/<mark>(.*?)<\/mark>/).flatten.uniq
      terms.sort_by(&:length).reverse
    end

    class_methods do
      private
        def remove_invalid_search_characters(terms)
          terms.gsub(/[^\w"]/, " ")
        end

        def remove_unbalanced_quotes(terms)
          if terms.count("\"").even?
            terms
          else
            terms.gsub("\"", " ")
          end
        end
    end
end
