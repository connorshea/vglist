# typed: strict

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `GeneratedUrlHelpersModule`.
# Please instead update this file by running `bin/tapioca dsl GeneratedUrlHelpersModule`.

module GeneratedUrlHelpersModule
  include ::ActionDispatch::Routing::UrlFor
  include ::ActionDispatch::Routing::PolymorphicRoutes

  sig { params(args: T.untyped).returns(String) }
  def about_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def activity_following_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def activity_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def activity_user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def add_game_to_library_game_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def add_to_wikidata_blocklist_game_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_add_to_steam_blocklist_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_games_without_wikidata_ids_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_new_steam_blocklist_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_remove_from_steam_blocklist_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_remove_from_wikidata_blocklist_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_steam_blocklist_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def admin_wikidata_blocklist_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def ban_user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def bulk_update_game_purchases_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def cancel_user_registration_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def companies_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def company_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def compare_users_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def connect_steam_user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def destroy_user_session_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def disconnect_steam_user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_company_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_engine_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_game_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_genre_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_oauth_application_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_platform_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_series_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_store_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_user_password_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_user_registration_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def edit_user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def engine_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def engines_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def event_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def favorite_game_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def favorited_game_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def favorites_user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def followers_user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def following_user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def game_purchase_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def game_purchases_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def game_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def games_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def genre_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def genres_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def graphiql_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def graphql_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def home_index_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def merge_game_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def native_oauth_authorization_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_company_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_engine_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_game_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_genre_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_oauth_application_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_platform_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_series_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_store_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_user_confirmation_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_user_password_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_user_registration_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_user_session_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def new_user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_application_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_applications_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_authorization_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_authorized_application_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_authorized_applications_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_introspect_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_revoke_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_token_info_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def oauth_token_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def opensearch_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def platform_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def platforms_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_blob_representation_proxy_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_blob_representation_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_blob_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_direct_uploads_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_disk_service_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_info_properties_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_info_routes_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_info_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_mailers_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_representation_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_service_blob_proxy_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_service_blob_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_storage_proxy_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def rails_storage_redirect_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def remove_avatar_user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def remove_cover_game_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def remove_game_from_library_game_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def reset_game_library_user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def reset_token_users_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def root_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_companies_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_engines_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_games_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_genres_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_platforms_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_series_index_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_stores_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def search_users_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def series_index_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def series_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def settings_account_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def settings_api_token_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def settings_export_as_json_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def settings_export_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def settings_import_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def settings_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def statistics_user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def steam_import_user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def store_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def stores_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def unban_user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def unfavorite_game_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def update_rails_disk_service_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def update_role_user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def user_confirmation_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def user_follow_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def user_password_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def user_registration_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def user_session_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def user_unfollow_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def user_url(*args); end

  sig { params(args: T.untyped).returns(String) }
  def users_url(*args); end
end
