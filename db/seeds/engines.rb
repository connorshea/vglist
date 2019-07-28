# typed: strict
puts "Creating Engines..."

10.times do
  Engine.create!(name: Faker::Game.unique.engine)
end
