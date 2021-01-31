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
    expected.stringify_keys!
    array_of_hashes.map!(&:stringify_keys)
    array_of_hashes.any? do |element|
      element.slice(*expected.keys) == expected
    end
  end

  failure_message do |array_of_hashes|
    expected_pairs = []
    expected.each_pair do |k, v|
      expected_pairs << "#{k}: #{v.inspect}"
    end
    "expected #{array_of_hashes} to have at least one hash with these attributes:\n#{expected_pairs.join("\n")}"
  end

  failure_message_when_negated do |array_of_hashes|
    "expected #{array_of_hashes} not to include key-value pairs #{expected.to_s.gsub(/\{|\}/, '')}."
  end
end
