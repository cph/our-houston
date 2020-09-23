# Sprockets can deadlock when trying to compile assets in parallel
# cf. https://github.com/rails/sprockets/issues/640
Sprockets.export_concurrent = false

Rails.application.config.assets.precompile += %w{
  roboto.css
}
