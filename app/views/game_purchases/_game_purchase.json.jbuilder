json.extract! game_purchase, :id, :score, :purchase_date, :comment
json.url game_purchase_url(game_purchase, format: :json)
json.cover_url url_for(game_purchase.game.cover) if game_purchase.game.cover.attached?
json.game_url game_url(game_purchase.game)
json.game game_purchase.game
