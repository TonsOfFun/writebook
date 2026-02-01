class RenameLeafToChapter < ActiveRecord::Migration[8.2]
  def change
    # Rename leaves table to chapters
    rename_table :leaves, :chapters

    # Rename leafable columns to chapterable in chapters table
    rename_column :chapters, :leafable_id, :chapterable_id
    rename_column :chapters, :leafable_type, :chapterable_type

    # Update edits table
    rename_column :edits, :leaf_id, :chapter_id
    rename_column :edits, :leafable_id, :chapterable_id
    rename_column :edits, :leafable_type, :chapterable_type

    # Update foreign key for edits
    if foreign_key_exists?(:edits, :leaves)
      remove_foreign_key :edits, :leaves
      add_foreign_key :edits, :chapters
    end

    # Rename the FTS virtual table (drop and recreate)
    execute "DROP TABLE IF EXISTS leaf_search_index"
    execute "CREATE VIRTUAL TABLE chapter_search_index USING fts5(title, content, tokenize='porter')"
  end
end
