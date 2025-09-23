class AddBodyToSections < ActiveRecord::Migration[8.0]
  def change
    change_table :sections do |t|
      t.text :body
    end

    execute "update sections set body = l.title from leaves l where l.leafable_id = sections.id and l.leafable_type = 'Section'"
  end
end
