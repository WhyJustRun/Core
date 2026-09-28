# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WhyJustRun Core is a Ruby on Rails application providing authentication, IOF XML APIs, and cross-club pages for [whyjustrun.ca](https://whyjustrun.ca). It works alongside the separate [WhyJustRun Clubsite](https://github.com/WhyJustRun/Clubsite) app.

## Development Commands

All commands run inside Docker containers:

```bash
# Start the app (localhost:3000)
docker compose up --build

# Database setup (first time)
docker compose exec core bundle exec rails db:reset db:populate_example_data

# Run migrations
docker compose exec core rake db:migrate

# Update gems
docker compose exec core bundle update

# Rails console
docker compose exec core bundle exec rails console

# Run tests
docker compose exec core bundle exec rails test

# Run a single test file
docker compose exec core bundle exec rails test test/unit/user_test.rb
```

Test users (password: "password"): admin@example.com, webmaster@example.com, executive@example.com, user@example.com

## Architecture

- **Database**: MariaDB via mysql2 adapter
- **Auth**: Devise (with legacy CakePHP password migration via devise-encryptable)
- **Authorization**: Pundit policies in `app/policies/`
- **IOF XML API**: Routes under `iof/:iof_version/` serving orienteering federation XML format, parsed with Nokogiri/Nori
- **Cross-app sessions**: Shared authentication with the Clubsite app via `CrossAppSession` model
- **Privilege system**: Role-based access with numeric levels (0-100) defined in `config/settings.yml`
- **Cron jobs**: Managed by the `whenever` gem
- **Frontend**: Bootstrap with CoffeeScript, Webpacker, jQuery, Leaflet for maps
- **Testing**: Minitest with fixtures in `test/fixtures/`
