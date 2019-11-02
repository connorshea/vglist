# typed: strict
puts "Creating Companies..."

20.times do
  Company.create!(
    name: Faker::Game.unique.company
  )
end
