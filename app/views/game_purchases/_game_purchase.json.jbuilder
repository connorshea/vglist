json.extract! game_purchase, :id, :score, :purchase_date, :comment
json.url game_purchase_url(game_purchase, format: :json)

json.game game_purchase.game
