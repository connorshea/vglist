# typed: true
# Given a response body, parse the JSON and access the specific type of search
# result we want.
#
# `searchables` is in roughly this format:
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
# @return [Array<Hash>] An array of hashes.
def searchable_helper(searchables, type)
  return JSON.parse(searchables)[type]
end
