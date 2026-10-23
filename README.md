# WhyJustRun Core

Source code for [whyjustrun.ca](https://whyjustrun.ca) and club websites.

## Usage

The app can easily be run using Docker.

1) Use the default configuration: `cp .env.core{.sample,}`
2) Start the container: `docker compose up --build`
3) Set up the database: `docker compose exec core bundle exec rails db:reset db:populate_example_data`

You should be up and running. Head to [localhost:3000](http://localhost:3000/).

To install/update gems, it's easiest to first run the container, and then run bundler commands inside the container. For example, to update the gems, use `docker compose exec core bundle update`.
### Test Users

By running the Rails task `db:populate_example_data`, a test club and several test users are set up with various privilege levels:
admin@example.com, webmaster@example.com, executive@example.com, user@example.com
Password for all accounts is: "password".

### Keeping up to date

When the database schema changes, you'll need to migrate your database: `docker compose exec core rake db:migrate`

When additional config params (via environment variables) are added, you may need to update your `.env.core` configuration.

### Platform administration

The apex site's `/admin` dashboard requires a global privilege at level 100 (a group with no club). Club administrator roles do not grant access. To bootstrap an administrator, first verify the person's user ID, then run:

```bash
docker compose exec core bundle exec rails 'admin:grant_global_admin[USER_ID]'
```

Replace `USER_ID` with the verified numeric ID. This grants access across all clubs as well as the dashboard. Repeating the command reuses the existing group and privilege.

The dashboard searches by name, email or ID and requires typing the target ID before deletion. Self-deletion and deletion of global privilege holders are blocked. Deletion removes the account, memberships and roles, and preserves results under a locked placeholder without sign-in credentials called `(deleted)`. Registrant comments are cleared and uploader references are detached in the same transaction.

Review uploaded result files, official comments, page content and backups separately: the dashboard does not remove names or other personal information embedded in those records or external files.
