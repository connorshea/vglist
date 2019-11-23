# typed: true
class CreateStores < ActiveRecord::Migration[6.0]
  def change
    create_table :stores do |t|
      t.text :name, null: false

      t.timestamps
    end
  end
end
