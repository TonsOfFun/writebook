class CreateAgentReferences < ActiveRecord::Migration[8.2]
  def change
    create_table :agent_references do |t|
      # Parent context - every reference comes from an agent context
      t.references :agent_context, null: false, foreign_key: true, index: true

      # The tool call that discovered this reference (optional, for traceability)
      t.references :agent_tool_call, foreign_key: true, index: true

      # Core reference data
      t.string :url, null: false
      t.string :title
      t.text :description

      # Open Graph / meta data
      t.string :og_title
      t.text :og_description
      t.string :og_image
      t.string :og_site_name
      t.string :og_type

      # Favicon
      t.string :favicon_url

      # Additional metadata
      t.string :domain           # Extracted domain for display
      t.json :metadata, default: {}  # Any additional scraped data

      # Content extracted from this reference
      t.text :extracted_content  # Summary of content extracted from this URL

      # Status
      t.string :status, default: "pending"  # pending, fetching, complete, failed
      t.text :error_message

      # Position for ordering
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :agent_references, :url
    add_index :agent_references, :domain
    add_index :agent_references, [:agent_context_id, :position]
  end
end
