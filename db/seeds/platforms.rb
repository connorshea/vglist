puts "Creating Platforms..."

# Create 20 Platforms.
20.times do
  Platform.create!(
    name: Faker::Game.unique.platform,
    wikidata_id: Faker::Number.unique.number(digits: 6)
  )
end
