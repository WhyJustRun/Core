source 'http://rubygems.org'

gem 'rails', '~> 8.1'
gem 'mysql2', '~> 0.5.7'

# Use the Puma web server
gem 'puma', '~> 8.0'

# MySQL Session store

# Asset pipeline
gem 'sass-rails', '~> 6.0.0'
gem "coffee-script", "~> 2.4.1"
gem "coffee-rails", "~> 5.0.0"
gem "uglifier", "~> 4.2.1"
gem 'tzinfo-data'

# Authentication
gem 'bcrypt', '~> 3.1.22'
gem 'devise', '~> 5.0.3'
gem "devise-encryptable", "~> 0.3.0"

# Maps
gem "leaflet-rails", "~> 1.9.3"

# Spam prevention
gem "recaptcha", "~> 5.21.2", :require => "recaptcha/rails"

# Jobs
gem 'whenever', '~> 1.1.4'

# Bootstrap
gem 'bootstrap-sass', '~> 3.4.1'

gem 'jquery-rails', '~> 4.6.1'

# XML Parsing
gem 'nokogiri', '~> 1.19.1'
gem 'nori', '~> 2.9.1'

gem "config", "~> 5.6.1"

gem 'icalendar', '~> 2.13.0'
gem "geocoder", "~> 1.8.6"

# JSON Builder
gem 'jbuilder', '~> 2.15.1'

# json 3 removed keywords still used by Rails 7.x and ExecJS 2.9.
gem 'json', '< 3'

# Logging (email)
gem "exception_notification", "~> 5.0"

# Authorization
gem "pundit", "~> 2.5.2"

# Image thumbnail generation (requires ImageMagick)
gem 'image_processing', '~> 2.2'

# image_processing 2.x makes MiniMagick a soft dependency.
gem 'mini_magick'

# Geo
gem 'haversine', '~> 0.3.2'

group :development, :test do
  gem 'brakeman', require: false
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver', '~> 4.52.0'
end
