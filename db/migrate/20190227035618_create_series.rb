# typed: true
class CreateSeries < ActiveRecord::Migration[5.2]
  def change
    create_table :series do |t|
      t.text :name, null: false, default: ""

      t.timestamps
    end
  end
end
