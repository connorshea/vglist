# typed: strict
puts "Creating Series..."

# Create 20 Series.
20.times do
  Series.create!(
    name: Faker::Game.unique.series,
    wikidata_id: Faker::Number.unique.number(digits: 6)
  )
end
