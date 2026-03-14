class Mutations::Users::ExportLibrary < Mutations::BaseMutation
  description "Export the current user's game library as JSON."

  field :library_json, String, null: true, description: "The exported library data as a JSON string."
  field :errors, [String], null: false, description: "Error messages if export failed."

  def resolve
    user = context[:current_user]
    raise GraphQL::ExecutionError, "You must be logged in to export your library." if user.nil?

    game_purchases = user.game_purchases.includes(:game, :platforms, :stores)

    library_data = game_purchases.map do |gp|
      {
        game: {
          id: gp.game.id,
          name: gp.game.name,
          wikidata_id: gp.game.wikidata_id
        },
        hours_played: gp.hours_played,
        completion_status: gp.completion_status,
        rating: gp.rating,
        start_date: gp.start_date,
        completion_date: gp.completion_date,
        comments: gp.comments,
        replay_count: gp.replay_count,
        platforms: gp.platforms.map { |p| { id: p.id, name: p.name } },
        stores: gp.stores.map { |s| { id: s.id, name: s.name } }
      }
    end

    { library_json: library_data.to_json, errors: [] }
  end
end
