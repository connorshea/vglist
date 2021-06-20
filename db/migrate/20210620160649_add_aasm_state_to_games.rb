# typed: true
class AddAasmStateToGames < ActiveRecord::Migration[6.1]
  def change
    add_column :games, :aasm_state, :string
  end
end
