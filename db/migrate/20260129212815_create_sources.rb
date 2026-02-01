class CreateSources < ActiveRecord::Migration[8.2]
  def change
    create_table :sources do |t|
      t.references :report, null: false, foreign_key: true
      t.string :name, null: false
      t.string :source_type, null: false  # pdf, image, text, url
      t.string :url                        # for URL sources
      t.text :raw_content                  # original text content or URL content
      t.text :extracted_content            # processed/extracted content for AI
      t.text :summary                      # AI-generated summary
      t.json :metadata, default: {}        # additional source metadata (page count, dimensions, etc.)
      t.string :processing_status, default: "pending"
      t.text :processing_error
      t.datetime :processed_at

      t.timestamps
    end

    add_index :sources, :source_type
    add_index :sources, :processing_status
  end
end
