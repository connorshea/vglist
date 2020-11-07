# typed: true
# Fetches an avatar image from Faker, or uses an image from the test suite
# if in CI, to avoid external HTTP requests.
def avatar_fetcher
  if ENV['CI']
    File.open('./spec/factories/images/avatar.jpg')
  else
    T.unsafe(URI.parse(Faker::Image.unsplash(width: 400, height: 400))).open
  end
end

puts "Creating Users..."

# Create 30 random users.
30.times do |n|
  user = User.create!(
    email: Faker::Internet.unique.email,
    # Usernames must be between (inclusive) 3 and 20 characters.
    username: Faker::Internet.unique.username(specifier: 3..20),
    # Passwords can be up to 128 characters, but we'll just do up to 20 here.
    password: Faker::Internet.password(min_length: 8, max_length: 20),
    bio: Faker::Lorem.sentence
  )

  # Only attach an avatar for some of the users.
  next unless rand(0..2) > 1

  user.avatar&.attach(
    io: avatar_fetcher,
    filename: "#{n}_faker_avatar.jpg"
  )
end

# Create 4 moderators.
4.times do
  User.create!(
    email: Faker::Internet.unique.email,
    # Usernames must be between (inclusive) 3 and 20 characters.
    username: Faker::Internet.unique.username(specifier: 3..20),
    # Passwords can be up to 128 characters, but we'll just do up to 20 here.
    password: Faker::Internet.password(min_length: 8, max_length: 20),
    bio: Faker::Lorem.sentence,
    role: :moderator
  )
end

# Create 2 private accounts
2.times do
  User.create!(
    email: Faker::Internet.unique.email,
    # Make private users with similar names
    username: "private_user#{Faker::Number.number(digits: 3)}",
    # Passwords can be up to 128 characters, but we'll just do up to 20 here.
    password: Faker::Internet.password(min_length: 8, max_length: 20),
    bio: Faker::Lorem.sentence,
    privacy: :private_account
  )
end

# Create 2 banned accounts
2.times do
  User.create!(
    email: Faker::Internet.unique.email,
    # Make banned users with similar names
    username: "banned_user#{Faker::Number.number(digits: 3)}",
    # Passwords can be up to 128 characters, but we'll just do up to 20 here.
    password: Faker::Internet.password(min_length: 8, max_length: 20),
    bio: Faker::Lorem.sentence,
    banned: true
  )
end
