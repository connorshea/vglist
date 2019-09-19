# typed: true
# Fetches a cover image from LoremPixel, or uses an image from the test suite
# if in CI, to avoid external HTTP requests.
def cover_fetcher
  if ENV['CI']
    File.open('./spec/factories/images/crysis.jpg')
  else
    # TODO: Make the dimensions more random.
    URI.open("#{Faker::LoremPixel.image(size: '560x800', is_gray: false)}/")
  end
end

puts "Creating Games..."

# Create 50 random Games.
50.times do |n|
  genres = []
  rand(0..3).times.each do
    genres << Genre.find(rand(1..Genre.count))
  end
  genres.uniq!

  engines = []
  rand(0..3).times.each do
    engines << Engine.find(rand(1..Engine.count))
  end
  engines.uniq!

  game = Game.create!(
    name: Faker::Game.unique.title,
    description: Faker::Lorem.sentence,
    genres: genres,
    engines: engines,
    series: Series.find(rand(1..Series.count)),
    release_date: Faker::Date.between(from: 25.years.ago, to: 2.years.from_now)
  )

  next unless rand(0..4) != 0

  # Add a cover for most games.
  game&.cover&.attach(
    io: cover_fetcher,
    filename: "#{n}_faker_cover.jpg"
  )
end
