# WhyJustRun Core

Source code for [whyjustrun.ca](https://whyjustrun.ca). Provides primarily authentication, IOF XML APIs, and cross-club pages.

See also [WhyJustRun Clubsite](https://github.com/WhyJustRun/Clubsite), which provides a web app for clubs.

## Usage

The app can easily be run using Docker.

1) Use the default configuration: `cp .env.core{.sample,}`
2) Start the container: `docker-compose up --build`
3) Set up the database: `docker-compose exec core bundle exec rails db:reset db:populate_example_data`

You should be up and running. Head to [localhost:3000](http://localhost:3000/).

To install/update gems, it's easiest to first run the container, and then run bundler commands inside the container. For example, to update the gems, use `docker-compose exec core bundle update`.
### Test Users

By running the Rails task `db:populate_example_data`, a test club and several test users are set up with various privilege levels:
admin@example.com, webmaster@example.com, executive@example.com, user@example.com
Password for all accounts is: "password".

### Keeping up to date

When the database schema changes, you'll need to migrate your database: `docker-compose exec core rake db:migrate`

When additional config params (via environment variables) are added, you may need to update your `.env.core` configuration.
