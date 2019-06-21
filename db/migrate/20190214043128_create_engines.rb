# typed: true
class CreateEngines < ActiveRecord::Migration[5.2]
  def change
    create_table :engines do |t|
      t.text :name, null: false, default: ""

      t.timestamps
    end
  end
end
