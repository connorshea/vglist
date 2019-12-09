# typed: strict
puts "Creating Stores..."

# Create 10 Stores.
10.times do
  Store.create!(
    name: Faker::Game.unique.store
  )
end
