# Sprockets can deadlock when trying to compile assets in parallel
# cf. https://github.com/rails/sprockets/issues/640
Sprockets.export_concurrent = false

# Needed to declare explicitly for Rails 5.1+
Rails.application.config.assets.unknown_asset_fallback = true

Rails.application.config.assets.precompile += %w{
  roboto.css
}
