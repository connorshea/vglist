# Return a hash where the keys are the possible types of records and the values are arrays of results.
# Like so:
# {
#   'Game': [{ id: 1 }, { id: 2 }],
#   'Company': [{ id: 1 }, { id: 2 }, { id: 3 }]
# }
@searchable_types.each do |type|
  json.set! type.to_sym do
    results_of_type = @search_results.select { |result| result[:searchable_type] == type }
    if type == 'Game'
      json.array!(results_of_type) do |pg_search|
        json.id pg_search.searchable.id
        json.content pg_search.content
        json.searchable_type pg_search.searchable_type
        json.searchable_id pg_search.searchable_id
        if pg_search.searchable.cover.attached?
          json.cover_url rails_blob_path(pg_search.searchable.cover, disposition: "attachment")
        else
          json.cover_url asset_path('no-cover.png')
        end
        json.developer pg_search.searchable.developers&.first&.name
        json.release_date pg_search.searchable.release_date
      end
    else
      json.array! results_of_type, :id, :content, :searchable_type, :searchable_id
    end
  end
end
