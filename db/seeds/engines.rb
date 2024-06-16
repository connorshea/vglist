# typed: strict
puts "Creating Engines..."

10.times do
  Engine.create!(
    name: Faker::Game.unique.engine,
    wikidata_id: Faker::Number.unique.number(digits: 6)
  )
end
