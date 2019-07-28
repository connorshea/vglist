# typed: strict
puts "Creating Advanced Users..."

# Exit early if there are less than 10 games.
return if Game.count < 10

# Seed users and then give them game purchases.
Rake::Task['db:seed:users'].invoke
Rake::Task['db:seed:game_purchases'].invoke
