puts "Creating Genres..."

# Create 20 unique genres.
20.times do
  Genre.create!(
    name: Faker::Game.unique.genre,
    wikidata_id: Faker::Number.unique.number(digits: 6)
  )
end
