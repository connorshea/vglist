# typed: strict
require Rails.root.join('lib/kaminari_rbi_plugin')
SorbetRails::ModelRbiFormatter.register_plugin(KaminariRbiPlugin)
