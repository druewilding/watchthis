# rails-server-template

> A minimal Rails starter with [klods-ruby](https://github.com/druewilding/klods-ruby) wired up and ready to go.

The Rails equivalent of [express-server-template](https://github.com/druewilding/express-server-template) — same page structure, same klods components, different runtime.

## What's included

- Rails 8.1 with no database (add one when you need it)
- [klods-ruby](https://github.com/druewilding/klods-ruby) — all builders available in every HAML view via Railtie
- [haml-rails](https://github.com/haml/haml-rails) — HAML template engine
- klods CSS loaded from CDN
- klods-js loaded via importmap for interactive components (sidebar toggle, tabs, modals)
- Page layout with header, collapsible sidebar, content area, and footer
- `content_for :sidebar` for per-view sidebar content
- `content_for :title` for per-view page titles
- `/` — welcome page
- `/ping` — plain text health check
- `/api/v1/status` — JSON API status endpoint

## Getting started

```sh
git clone https://github.com/druewilding/rails-server-template myapp
cd myapp
bundle install
bin/rails server
```

Open [http://localhost:3000](http://localhost:3000).

## Using klods

All builders are available in every HAML view and layout — no imports needed.

Use `do` blocks to nest components — the indentation mirrors the HTML structure:

```haml
= stack({ gap: 4 }) do
  = prose do
    = h1({ id: "section" }, "My Page")
    = p("Content goes here.")
  = cluster({ gap: 2 }) do
    = button({ variant: "primary" }, "Save")
    = button("Cancel")
```

Pass title and sidebar content from any view:

```haml
- content_for :title, "My Page"
- content_for :sidebar, toc([toc_item(toc_link({ href: "#section" }, "My Page"))])

= stack({ gap: 4 }) do
  = prose do
    = h1({ id: "section" }, "My Page")
    = p("Content goes here.")
```

See the [klods-ruby docs](https://github.com/druewilding/klods-ruby) for the full component API.

## Key files

| File                                          | Purpose                                       |
| --------------------------------------------- | --------------------------------------------- |
| `app/views/layouts/application.html.haml`     | Page shell (header, sidebar, content, footer) |
| `app/views/welcome/index.html.haml`           | Welcome page — replace with your own views    |
| `app/controllers/welcome_controller.rb`       | Root and ping routes                          |
| `app/controllers/api/v1/status_controller.rb` | JSON API                                      |
| `config/routes.rb`                            | All routes                                    |
| `config/importmap.rb`                         | klods-js pinned from CDN                      |
| `app/javascript/application.js`               | Sidebar toggle wiring                         |

## Adding a database

```sh
bundle add sqlite3  # or pg, mysql2, etc.
bin/rails generate model ...
```

You'll also need to add `gem "activerecord"` and configure `config/database.yml`.

## Development

```sh
bin/rails server           # start dev server
bin/rails routes           # list all routes
bin/rails test             # run controller and integration tests
bin/rails test:system      # run system tests (requires Chrome)
bin/standardrb             # check style
bin/standardrb --fix       # auto-fix style
```
