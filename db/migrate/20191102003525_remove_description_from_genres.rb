# typed: true
class RemoveDescriptionFromGenres < ActiveRecord::Migration[6.0]
  def change
    remove_column :genres, :description, :text
  end
end
