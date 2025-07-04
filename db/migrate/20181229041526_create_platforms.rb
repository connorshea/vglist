class CreatePlatforms < ActiveRecord::Migration[5.2]
  def change
    create_table :platforms do |t|
      t.text :name, null: false
      t.text :description, null: false, default: ""

      t.timestamps
    end
  end
end
