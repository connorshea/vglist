# typed: strict
puts "Creating Companies..."

20.times do
  Company.create!(
    name: Faker::Game.unique.company,
    wikidata_id: Faker::Number.unique.number(digits: 6)
  )
end
