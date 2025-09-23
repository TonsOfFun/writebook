class AddCustomStylesToAccount < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :custom_styles, :text
  end
end
