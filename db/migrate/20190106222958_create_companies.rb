# typed: true
class CreateCompanies < ActiveRecord::Migration[5.2]
  def change
    create_table :companies do |t|
      t.text :name, null: false, default: ""
      t.text :description, null: false, default: ""

      t.timestamps
    end
  end
end
