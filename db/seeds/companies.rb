puts "Creating Companies..."

20.times do
  Company.create!(
    name: Faker::Game.unique.company,
    description: Faker::Lorem.sentence
  )
end
