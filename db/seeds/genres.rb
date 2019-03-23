puts "Creating Genres..."

# Create 20 unique genres.
20.times do
  Genre.create!(
    name: Faker::Game.unique.genre,
    description: Faker::Lorem.sentence
  )
end
