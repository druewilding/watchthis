# WatchThis

> Share media with friends — YouTube videos, articles, music, and more.

## What it is

WatchThis lets you share URLs with friends and keep track of what you've watched. Send someone a YouTube video, they get it in their inbox, they mark it watched when they're done. You can also save things to your own lists for later.

Built as a Rails monolith — a rewrite of an over-engineered Node.js microservices version that got abandoned under its own weight.

## Stack

- Rails 8.1 + PostgreSQL
- [klods-ruby](https://github.com/druewilding/klods-ruby) for all views via HAML
- Devise for authentication
- Turbo + Stimulus for interactive bits
- klods CSS + JS from CDN

## Getting started

```sh
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

Open [http://localhost:3000](http://localhost:3000).

## Development

```sh
bin/rails server           # start dev server
bin/rails routes           # list all routes
bin/rails test             # run controller and integration tests
bin/rails test:system      # run system tests (requires Chrome)
bin/standardrb             # check style
bin/standardrb --fix       # auto-fix style
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for the domain model, database schema, and build plan.
