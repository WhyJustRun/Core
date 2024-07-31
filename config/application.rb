require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module WhyJustRun
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Enable the asset pipeline
    config.assets.enabled = true

    # Configure static file server for performance
    config.serve_static_files = true
    config.static_cache_control = "public, max-age=3600"

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Specify timezone for active record
    config.active_record.default_timezone = :utc
    config.time_zone = 'UTC'

    # Enable gzip
    config.middleware.use Rack::Deflater
  end
end
