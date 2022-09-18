# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `GeneratedPathHelpersModule`.
# Please instead update this file by running `bin/tapioca dsl GeneratedPathHelpersModule`.

module GeneratedPathHelpersModule
  include ::ActionDispatch::Routing::UrlFor
  include ::ActionDispatch::Routing::PolymorphicRoutes

  sig { params(args: T.untyped).returns(String) }
  def about_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def activity_following_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def activity_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def activity_user_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def add_game_to_library_game_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def add_to_wikidata_blocklist_game_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_add_to_steam_blocklist_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_games_without_wikidata_ids_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_new_steam_blocklist_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_remove_from_steam_blocklist_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_remove_from_wikidata_blocklist_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_steam_blocklist_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_unmatched_game_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_unmatched_games_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_wikidata_blocklist_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def ban_user_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def bulk_update_game_purchases_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def cancel_user_registration_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def companies_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def company_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def compare_users_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def connect_steam_user_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def destroy_user_session_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def disconnect_steam_user_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_company_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_engine_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_game_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_genre_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_oauth_application_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_platform_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_series_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_store_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_user_password_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_user_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_user_registration_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def engine_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def engines_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def event_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def favorite_game_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def favorited_game_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def favorites_user_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def followers_user_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def following_user_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def game_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def game_purchase_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def game_purchases_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def games_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def genre_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def genres_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def graphiql_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def graphql_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def home_index_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def merge_game_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def native_oauth_authorization_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_company_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_engine_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_game_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_genre_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_oauth_application_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_platform_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_series_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_store_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_user_confirmation_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_user_password_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_user_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_user_registration_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_user_session_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_application_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_applications_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_authorization_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_authorized_application_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_authorized_applications_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_introspect_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_revoke_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_token_info_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_token_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def opensearch_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def platform_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def platforms_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_blob_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_blob_representation_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_blob_representation_proxy_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_direct_uploads_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_disk_service_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_info_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_info_properties_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_info_routes_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_mailers_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_representation_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_service_blob_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_service_blob_proxy_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_storage_proxy_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_storage_redirect_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def remove_avatar_user_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def remove_cover_game_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def remove_game_from_library_game_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def reset_game_library_user_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def reset_token_users_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def root_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_companies_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_engines_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_games_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_genres_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_platforms_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_series_index_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_stores_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_users_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def series_index_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def series_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def settings_account_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def settings_api_token_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def settings_export_as_json_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def settings_export_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def settings_import_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def settings_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def statistics_user_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def steam_import_user_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def store_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def stores_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def unban_user_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def unfavorite_game_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def update_rails_disk_service_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def update_role_user_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def user_confirmation_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def user_follow_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def user_password_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def user_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def user_registration_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def user_session_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def user_unfollow_path(*args); end

  sig { params(args: T.untyped).returns(String) }
  def users_path(*args); end
end
