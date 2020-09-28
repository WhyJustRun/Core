# Usage

The app can easily be run using Docker.

1) Use the default configuration: `cp .env.web{.sample,}`
2) Start the container: `docker-compose up --build`
3) Set up the database: `docker-compose exec web rake db:create db:schema:load`

You should be up and running. Head to [localhost:3000](http://localhost:3000/)


## Keeping up to date

When the database schema changes, you'll need to migrate your database: `docker-compose exec web rake db:migrate`

When additional config params (via environment variables) are added, you may need to update your `.env.web` configuration.