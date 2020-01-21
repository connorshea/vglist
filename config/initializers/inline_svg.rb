# typed: false

require './lib/custom_webpack_asset_finder'

InlineSvg.configure do |config|
  config.asset_finder = CustomWebpackAssetFinder
  config.raise_on_file_not_found = true
end
