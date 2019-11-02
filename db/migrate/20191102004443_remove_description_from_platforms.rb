# typed: true
class RemoveDescriptionFromPlatforms < ActiveRecord::Migration[6.0]
  def change
    remove_column :platforms, :description, :text
  end
end
