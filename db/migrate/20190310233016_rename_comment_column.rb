class RenameCommentColumn < ActiveRecord::Migration[5.2]
  def change
    change_table :game_purchases do |t|
      t.rename :comment, :comments
    end
  end
end
