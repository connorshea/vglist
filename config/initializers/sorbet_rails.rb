# typed: strict
require Rails.root.join('lib', 'kaminari_rbi_plugin')
require Rails.root.join('lib', 'pg_search_rbi_plugin')
require Rails.root.join('lib', 'friendly_id_rbi_plugin')
SorbetRails::ModelRbiFormatter.register_plugin(KaminariRbiPlugin)
SorbetRails::ModelRbiFormatter.register_plugin(PgSearchRbiPlugin)
SorbetRails::ModelRbiFormatter.register_plugin(FriendlyIdRbiPlugin)
