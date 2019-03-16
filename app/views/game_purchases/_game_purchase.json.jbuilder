json.extract! game_purchase,
  :id,
  :rating,
  :hours_played,
  :comments,
  :start_date,
  :completion_date

humanized_completion_statuses = {
  unplayed: 'Unplayed',
  in_progress: 'In Progress',
  dropped: 'Dropped',
  completed: 'Completed',
  fully_completed: '100% Completed',
  not_applicable: 'N/A'
}.with_indifferent_access

json.set! :completion_status do
  if game_purchase.completion_status
    json.set! :label, humanized_completion_statuses[game_purchase.completion_status]
    json.set! :value, game_purchase.completion_status
  else
    json.set! :label, ''
    json.set! :value, ''
  end
end

json.url game_purchase_url(game_purchase, format: :json)
json.cover_url url_for(game_purchase.game.cover) if game_purchase.game.cover.attached?
json.game_url game_url(game_purchase.game)
json.game game_purchase.game
