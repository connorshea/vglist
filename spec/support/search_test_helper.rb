# typed: true
# Given a response body, parse the JSON, access the specific type of search
# result we want, and return just the attributes we want.
#
# `searchables` is in this format:
#
# ```json
# {
#   "Game": [
#     {
#       "id": 1932,
#       "content": "Half-Life 2",
#       "searchable_type": "Game",
#       "searchable_id": 1932,
#       "image_url": null,
#       "developer": null,
#       "release_date": null
#     }
#   ],
#   "Series": [],
#   "Company": [],
#   "Platform": [],
#   "Engine": [],
#   "Genre": [],
#   "User": []
# }
# ```
#
# @param [String] searchables The JSON string representing the search results. See format above.
# @param [String] type The type of returned searchable to filter to, one of ['Game', 'Series', 'Company', 'Platform', 'Engine', 'Genre, 'User']
# @param [Array<Symbol>] keys The keys to return from the searchable objects, by default `searchable_id`, `content`, and `searchable_type`.
# @return [Array<Hash>] A hash with whatever keys are determined by `keys`.
def searchable_helper(searchables, type, keys = [:searchable_id, :content, :searchable_type])
  return JSON.parse(searchables)[type].map do |searchable|
    hash = {}
    keys.each do |key|
      hash[key] = searchable[key.to_s]
    end
    hash
  end
end
