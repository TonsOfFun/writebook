class CreateDocuments < ActiveRecord::Migration[8.2]
  def change
    create_table :documents do |t|
      t.json :page_text, default: {}
      t.json :page_images, default: {}
      t.integer :page_count, default: 0
      t.string :document_type
      t.string :processing_status, default: "pending"
      t.text :processing_error

      t.timestamps
    end

    add_index :documents, :document_type
    add_index :documents, :processing_status
  end
end
