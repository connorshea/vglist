# frozen_string_literal: true

class AddUsernameToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :username, :text, null: false
  end
end
