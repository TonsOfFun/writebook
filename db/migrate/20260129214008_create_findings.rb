class CreateFindings < ActiveRecord::Migration[8.2]
  def change
    create_table :findings do |t|
      t.string :severity, null: false, default: "medium"  # critical, high, medium, low, info
      t.string :status, null: false, default: "open"      # open, confirmed, resolved, wont_fix
      t.string :category                                   # security, performance, architecture, code_quality, compliance, other
      t.text :description                                  # detailed description/body
      t.text :recommendation                               # suggested remediation
      t.text :evidence                                     # supporting evidence/observations
      t.json :metadata, default: {}                        # additional structured data

      t.timestamps
    end

    add_index :findings, :severity
    add_index :findings, :status
    add_index :findings, :category
  end
end
