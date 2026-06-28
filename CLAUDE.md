# rails-server-template — CLAUDE.md

## What this is

A minimal Rails 7.2 starter with [klods-ruby](https://github.com/druewilding/klods-ruby) and HAML wired up. No database by default. The Rails equivalent of `express-server-template`.

## Stack

- **Rails 8.1** — no database configured by default
- **klods-ruby** — all builders available in every view via Railtie (no imports needed)
- **haml-rails** — HAML template engine; all views are `.html.haml`
- **klods CSS** — loaded from CDN in the layout
- **klods-js** — loaded via importmap from CDN for interactive components
- **StandardRB** — zero-config Ruby style linter

## Project layout

```
app/
  controllers/
    application_controller.rb          base controller
    welcome_controller.rb              root (/) and ping routes
    api/v1/status_controller.rb        JSON health endpoint
  views/
    layouts/application.html.haml      page shell (header, sidebar, content, footer)
    welcome/index.html.haml            welcome page — replace with your own views
config/
  routes.rb                            all routes
  importmap.rb                         klods-js pinned from CDN
```

## Routes

| Route                | Handler                          | Purpose                     |
| -------------------- | -------------------------------- | --------------------------- |
| `GET /`              | `WelcomeController#index`        | welcome page                |
| `GET /ping`          | `WelcomeController#ping`         | plain text health check     |
| `GET /api/v1/status` | `Api::V1::StatusController#show` | JSON `{status, message}`    |
| `GET /up`            | `rails/health#show`              | Rails built-in health check |

## HAML + klods patterns

All klods builders are available in every view — no include needed.

**Block syntax** (preferred for nesting):
```haml
= stack({ gap: 4 }) do
  = prose do
    = h1({ id: "welcome" }, "Welcome!")
    = p("Some text.")
  = cluster({ gap: 2 }) do
    = button({ variant: "primary" }, "Save")
    = button("Cancel")
```

**Variable assignment** (for one-liners or reuse):
```haml
- actions = cluster({ gap: 2 }, [button({ variant: "primary" }, "Save"), button("Cancel")])
= stack({ gap: 4 }) do
  = prose do
    = h1("Title")
  = actions
```

**One rule**: `=` output lines must be a single Ruby expression. Multi-line array literals break under HAML 6 because it inserts a semicolon after `[`. Use `do` blocks or `- var =` instead.

**Per-view title and sidebar**:
```haml
- content_for :title, "My Page"
- content_for :sidebar, toc([toc_item(toc_link({ href: "#section" }, "Section"))])
```
If `:sidebar` isn't set, the layout falls back to a default ToC with a Home link.

## Layout structure

`application.html.haml` builds the page shell with klods blocks:

```haml
= page({ sidebar: true }) do
  = header do ...
  = sidebar do
    - if content_for?(:sidebar)
      = Klods::Core.raw(content_for(:sidebar))
    - else
      = toc do ...
  = content do
    = Klods::Core.raw(yield)
  = footer("Rails Server Template")
```

`Klods::Core.raw(...)` is needed when wrapping already-rendered HTML (from `yield` or `content_for`) so it isn't double-escaped.

## Commands

```sh
bin/rails server              # start dev server (http://localhost:3000)
bin/rails routes              # list all routes
bundle exec standardrb        # check style
bundle exec standardrb --fix  # auto-fix style
bundle exec brakeman          # security scan
```

## Adding a database

```sh
bundle add pg  # or sqlite3, mysql2
# configure config/database.yml
bin/rails generate model ...
```

## klods-ruby version note

The Gemfile points at the published gem (`gem "klods-ruby"`). The block/`do` syntax requires klods-ruby ≥ 1.1.0. If that version isn't yet published, switch to the local path temporarily:

```ruby
gem "klods-ruby", path: "../klods-ruby"
```
