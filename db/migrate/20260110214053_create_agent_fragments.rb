class CreateAgentFragments < ActiveRecord::Migration[8.2]
  def change
    create_table :agent_fragments do |t|
      t.references :agent_context, foreign_key: true, null: false
      t.references :contextable, polymorphic: true  # Page, Section, etc.

      # Fragment identity
      t.string :fragment_type      # "selection", "generated", "applied"
      t.integer :start_offset      # Character position in document
      t.integer :end_offset        # End position for precise re-insertion
      t.string :content_hash       # SHA256 for change detection

      # Content versions
      t.text :original_content     # What user selected
      t.text :generated_content    # AI output
      t.text :applied_content      # What was actually applied (may be edited)

      # Metadata
      t.string :action_type        # "improve", "research", "expand", etc.
      t.json :detected_references  # [{url, title, accepted: bool}, ...]
      t.json :metadata             # Additional context

      # Status
      t.string :status, default: "pending"  # pending, generating, generated, applied, discarded

      # Version chain
      t.references :parent_fragment, foreign_key: { to_table: :agent_fragments }, null: true

      t.timestamps
    end

    add_index :agent_fragments, [:contextable_type, :contextable_id]
    add_index :agent_fragments, :content_hash
    add_index :agent_fragments, :status
  end
end
