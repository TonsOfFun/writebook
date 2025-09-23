class AddThemeToBook < ActiveRecord::Migration[8.0]
  change_table(:books) do |t|
    t.string :theme, default: "blue", null: false
  end
end
