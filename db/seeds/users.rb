# typed: true
# Fetches an avatar image from Faker, or uses an image from the test suite
# if in CI, to avoid external HTTP requests.
def avatar_fetcher
  if ENV['CI']
    File.open('./spec/factories/images/avatar.jpg')
  else
    URI.open(Faker::Avatar.image)
  end
end

puts "Creating Users..."

# Create 30 random users.
30.times do |n|
  user = User.create!(
    email: Faker::Internet.unique.email,
    # Usernames must be between (inclusive) 4 and 20 characters.
    username: Faker::Internet.unique.username(4..20),
    # Passwords can be up to 128 characters, but we'll just do up to 20 here.
    password: Faker::Internet.password(8, 20),
    bio: Faker::Lorem.sentence
  )

  # Only attach an avatar for some of the users.
  next unless rand(0..2) > 1

  user.avatar.attach(
    io: avatar_fetcher,
    filename: "#{n}_faker_avatar.jpg"
  )
end

# Create 5 moderators.
5.times do
  User.create!(
    email: Faker::Internet.unique.email,
    # Usernames must be between (inclusive) 4 and 20 characters.
    username: Faker::Internet.unique.username(4..20),
    # Passwords can be up to 128 characters, but we'll just do up to 20 here.
    password: Faker::Internet.password(8, 20),
    bio: Faker::Lorem.sentence,
    role: :moderator
  )
end
