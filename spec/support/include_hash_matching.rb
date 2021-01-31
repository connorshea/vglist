# typed: false
require 'rspec/expectations'

# Based on this StackOverflow question:
# https://stackoverflow.com/questions/23815944/rspec-match-array-of-hashes
# With some stringification to make the comparison work when inputting
# symbolized hashes.
#
# Will accept hashes that don't have every key from the returned hash.
#
# ```ruby
# users = [
#   {
#     id: 1,
#     username: 'foo',
#     avatar_url: '/images/abcdefghijklmnop12345.png'
#   },
#   {
#     id: 2,
#     username: 'bar',
#     avatar_url: '/images/xyzabcfoobarbaz98765.jpg'
#   }
# ]
#
# expected_user = {
#   id: 1,
#   username: 'foo'
# }
#
# expect(users).to include(expected_user)
#   #=> fails because `expected_user` doesn't have an `avatar_url` attribute.
# expect(users).to include_hash_matching(expected_user)
#   #=> passes! Now we don't need to include every possible attribute of the
#       returned user to get a match, we just need to match on everything in
#       `expected_user`.
# ```
RSpec::Matchers.define :include_hash_matching do |expected|
  match do |array_of_hashes|
    array_of_hashes.any? do |element|
      expected = expected.stringify_keys
      element = element.stringify_keys
      element.slice(*expected.keys) == expected
    end
  end
end
