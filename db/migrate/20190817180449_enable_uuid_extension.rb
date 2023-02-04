# typed: false
class EnableUuidExtension < ActiveRecord::Migration[6.0]
  def change
    enable_extension 'uuid-ossp'
  end
end
