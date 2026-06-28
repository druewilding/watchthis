# WatchThis — CLAUDE.md

## What this is

A media sharing Rails app. Users share URLs (YouTube videos, articles, anything) with friends. Recipients get them in an Inbox list and mark them watched. See [ARCHITECTURE.md](ARCHITECTURE.md) for the full domain model and build plan.

## Stack

- **Rails 8.1** + PostgreSQL
- **klods-ruby** — all builders available in every HAML view via Railtie; no imports needed
- **haml-rails** — all views are `.html.haml`
- **Devise** — email/password auth; no JWT
- **Turbo + Stimulus** — interactive bits; always use `status: :see_other` on redirects from non-GET actions (PATCH, DELETE, POST) so Turbo 8 follows them correctly
- **StandardRB** — style linter

## Domain at a glance

| Model | Key points |
|-------|-----------|
| `User` | Devise; gets a default Inbox `List` on registration |
| `Media` | Write-once, deduplicated by `normalized_url`; YouTube metadata via oEmbed |
| `Share` | `from_user → to_user` for a `Media`; status: `pending / watched / archived`; self-share is valid |
| `List` | User-owned collection; one default Inbox per user |
| `ListItem` | Ties `Media` to a `List`; optionally references the `Share` it came from |
| `Friendship` | Phase 4 — symmetric join with `pending / accepted` status |

## Project layout

```
app/
  controllers/
    application_controller.rb        before_action :authenticate_user! (except welcome)
    welcome_controller.rb            public landing page + ping
    dashboard_controller.rb          main authenticated view
    media_controller.rb              POST /media — add a URL
    shares_controller.rb             CRUD shares
    lists_controller.rb              CRUD lists
    list_items_controller.rb         PATCH/DELETE items within a list
    users/
      registrations_controller.rb    override Devise to create default Inbox on signup
    api/v1/
      status_controller.rb           health check
  models/
    user.rb  media.rb  share.rb  list.rb  list_item.rb
  views/
    layouts/application.html.haml   page shell (from rails-server-template)
    welcome/index.html.haml          public landing
    dashboard/index.html.haml        inbox + quick share
    lists/show.html.haml             list items with filtering
    shares/show.html.haml            single share detail
```

## Key behaviours to preserve

- **Media deduplication**: always look up by `normalized_url` before creating; one `Media` row per unique piece of content regardless of how many people share it
- **Inbox auto-creation**: `Users::RegistrationsController` calls `super`, then `current_user.lists.create!(name: "Inbox", is_default: true)` — always happens on signup, never on login
- **Incoming share → ListItem**: when a `Share` is created, auto-create a `ListItem` in the recipient's Inbox pointing at the same `Media`
- **Self-share is valid**: `from_user_id == to_user_id` is a "save to my list" action, not an error

## HAML + klods patterns

Use `do` blocks for nesting — the indentation mirrors the HTML:

```haml
= stack({ gap: 6 }) do
  = prose do
    = h1({ id: "inbox" }, "Inbox")
    = p("#{@inbox_items.count} items waiting")
  = @inbox_items.each do |item|
    = card do
      = card_title(item.media.title)
      = card_body(item.media.author)
```

Per-view title and sidebar:

```haml
- content_for :title, "Dashboard"
- content_for :sidebar, toc([toc_item(toc_link({ href: "#inbox" }, "Inbox")), toc_item(toc_link({ href: "#share" }, "Share something"))])
```

For forms, always use the klods form builder methods — the Railtie sets `Klods::FormBuilder` as the default, so no `builder:` option is needed on `form_with`:

```haml
= form_with(url: some_path, method: :post) do |f|
  = stack({ gap: 3 }) do
    = f.klods_field :email, label: "Email", type: :email, required: true
    = f.klods_field :name, label: "Name", help: "Your display name"
    = f.klods_textarea :bio, label: "Bio"
    = f.klods_select :role, [["Admin", "admin"], ["User", "user"]], label: "Role"
    = f.klods_submit "Save"
```

`klods_field` renders label + styled input + aria wiring + inline error message as a unit. `klods_submit` renders a primary-styled button. No need to use `f.label`, `f.text_field`, or `f.submit` separately.

## Commands

```sh
bin/rails server              # start dev server
bin/rails db:create db:migrate db:seed
bin/rails test                # controller + integration tests
bin/rails test:system         # system tests (requires Chrome)
bin/standardrb                # check style
bin/standardrb --fix          # auto-fix
bin/brakeman --no-pager       # security scan
```

## What's next (Phase 1)

1. Add `pg` and `devise` to Gemfile
2. `rails generate devise:install && rails generate devise User`
3. Override `Users::RegistrationsController` to create default Inbox
4. Migrations for all tables (see ARCHITECTURE.md for schema)
5. Seed with a test user and sample media
