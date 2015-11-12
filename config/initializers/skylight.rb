# Skylight assumes that config/skylight.yml will be relative Rails.root,
# so we specify the absolute path to the config file.
Houston::Application.config.skylight[:config_path] = Houston.root.join "config/skylight.yml"
