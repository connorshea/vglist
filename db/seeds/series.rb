puts "Creating Series..."

# Create 20 Series.
20.times do
  Series.create!(
    name: Faker::Game.unique.series
  )
end
