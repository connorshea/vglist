# typed: false

InlineSvg.configure do |config|
  config.asset_finder = InlineSvg::WebpackAssetFinder
  config.raise_on_file_not_found = true
end
