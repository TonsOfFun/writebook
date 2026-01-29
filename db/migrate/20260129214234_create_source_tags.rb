class CreateSourceTags < ActiveRecord::Migration[8.2]
  def change
    create_table :source_tags do |t|
      t.references :source, null: false, foreign_key: true
      t.references :taggable, polymorphic: true, null: false
      t.string :context                        # e.g., "page 12", "section 3.2"
      t.text :excerpt                          # relevant excerpt from source
      t.integer :position, default: 0          # ordering within a taggable

      t.timestamps
    end

    add_index :source_tags, [:taggable_type, :taggable_id, :source_id], unique: true, name: "index_source_tags_uniqueness"
  end
end
