# typed: true
class CreateGames < ActiveRecord::Migration[5.2]
  def change
    create_table :games do |t|
      t.text :name, null: false, default: ""
      t.text :description, null: false, default: ""
      t.timestamps
    end
  end
end
