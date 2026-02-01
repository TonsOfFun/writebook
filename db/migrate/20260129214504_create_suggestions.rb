class CreateSuggestions < ActiveRecord::Migration[8.2]
  def change
    create_table :suggestions do |t|
      t.references :suggestable, polymorphic: true, null: false
      t.references :author, null: true, foreign_key: { to_table: :users }
      t.references :resolved_by, null: true, foreign_key: { to_table: :users }
      t.string :suggestion_type, null: false, default: "edit"  # edit, add, delete, comment
      t.string :status, null: false, default: "pending"        # pending, accepted, rejected, resolved
      t.text :original_text                                    # text being replaced/modified
      t.text :suggested_text                                   # suggested replacement
      t.text :comment                                          # explanation or discussion
      t.integer :start_offset                                  # position in document
      t.integer :end_offset
      t.string :content_hash                                   # hash of surrounding content for anchoring
      t.boolean :ai_generated, default: false
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :suggestions, :status
    add_index :suggestions, :suggestion_type
    add_index :suggestions, :ai_generated
  end
end
