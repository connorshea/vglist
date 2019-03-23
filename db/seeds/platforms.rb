puts "Creating Platforms..."

# Create 20 Platforms.
20.times do
  Platform.create!(
    name: Faker::Game.unique.platform,
    description: Faker::Lorem.sentence
  )
end
