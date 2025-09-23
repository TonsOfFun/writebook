class CreateLeafSearchIndexTable < ActiveRecord::Migration[8.0]
  def change
    create_virtual_table "leaf_search_index", "fts5", [ "title", "content", "tokenize='porter'" ]

    Leaf.reindex_all
  end
end
