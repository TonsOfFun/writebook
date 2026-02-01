class RenameBookToReport < ActiveRecord::Migration[8.2]
  def change
    # Rename the books table to reports
    rename_table :books, :reports

    # Rename book_id foreign keys in related tables
    rename_column :accesses, :book_id, :report_id
    rename_column :leaves, :book_id, :report_id

    # Rename indexes (Rails handles this automatically with rename_column for most cases)
    # But we need to explicitly rename the foreign key constraints
    if foreign_key_exists?(:accesses, :books)
      remove_foreign_key :accesses, :books
      add_foreign_key :accesses, :reports
    end

    if foreign_key_exists?(:leaves, :books)
      remove_foreign_key :leaves, :books
      add_foreign_key :leaves, :reports
    end
  end
end
