# typed: strict
puts "Creating Stores..."

# Create 8 Stores.
8.times do
  Store.create!(
    name: Faker::Game.unique.store
  )
end
