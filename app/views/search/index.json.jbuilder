# If the type is complex, handle it separately so we can get the specific
# information we want for those types of search results.
complex_types = ['Game', 'User'].freeze

# Return a hash where the keys are the possible types of records and the values are arrays of results.
# Like so:
# {
#   'Game': [{ id: 1 }, { id: 2 }],
#   'Company': [{ id: 1 }, { id: 2 }, { id: 3 }]
# }
@searchable_types.each do |type|
  json.set! type.to_sym do
    results_of_type = @search_results.select { |result| result[:searchable_type] == type }
    if complex_types.include?(type)
      json.array!(results_of_type) do |pg_search|
        json.id pg_search.searchable.id
        json.content pg_search.content
        json.searchable_type pg_search.searchable_type
        json.searchable_id pg_search.searchable_id
        case type
        when 'Game'
          if pg_search.searchable.cover.attached?
            json.image_url rails_blob_path(pg_search.searchable.cover, disposition: "attachment")
          else
            json.image_url asset_path('no-cover.png')
          end
          json.developer pg_search.searchable.developers&.first&.name
          json.release_date pg_search.searchable.release_date
        when 'User'
          if pg_search.searchable.avatar.attached?
            json.image_url rails_blob_path(pg_search.searchable.avatar, disposition: "attachment")
          else
            json.image_url asset_path('default-avatar.png')
          end
        end
      end
    else
      json.array! results_of_type, :id, :content, :searchable_type, :searchable_id
    end
  end
end
