# frozen_string_literal: true

module Api
  module Admin
    # Exports every game's name, vglist ID, Steam app IDs, and Wikidata ID as a
    # single JSON file, so admins can diff vglist against Wikidata offline.
    #
    # This is a plain REST endpoint rather than a GraphQL query because the
    # GraphQL API is limited to an allowlist of first-party operations with
    # complexity limits and timeouts sized for paginated pages, not for a
    # whole-table dump. It authenticates with the same JWT bearer token the SPA
    # uses for GraphQL.
    class GamesExportsController < ApplicationController
      def show
        authorize nil, policy_class: ::Admin::GamesExportPolicy

        send_data games_json,
          type: :json,
          disposition: 'attachment',
          filename: "vglist-games-#{Time.now.utc.strftime('%Y-%m-%d')}.json"
      end

      private

      # Postgres builds the whole JSON document in one query, so there's no
      # per-game Ruby object allocation or N+1 on Steam app IDs. Each game is
      # ~100 bytes of JSON, so even tens of thousands of games is only a few
      # MB in memory.
      def games_json
        sql = <<~SQL.squish
          SELECT json_build_object(
            'exported_at', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
            'games', COALESCE(
              json_agg(
                json_build_object(
                  'id', games.id,
                  'name', games.name,
                  'steam_app_ids', COALESCE(steam.app_ids, '[]'::json),
                  'wikidata_id', games.wikidata_id
                )
                ORDER BY games.id
              ),
              '[]'::json
            )
          )
          FROM games
          LEFT JOIN (
            SELECT game_id, json_agg(app_id ORDER BY app_id) AS app_ids
            FROM steam_app_ids
            GROUP BY game_id
          ) steam ON steam.game_id = games.id
        SQL

        ActiveRecord::Base.connection.select_value(sql)
      end
    end
  end
end
