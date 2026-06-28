# WatchThis — Rails Edition

_Share media with friends — YouTube videos, articles, music, and more_

## Why Rails

The Node.js microservices version had too much infrastructure overhead: four separate services, JWT-to-session bridges, service-to-service HTTP calls, independent databases, and separate test suites per service. The core product idea is simple, and the complexity was getting in the way of building it.

Rails collapses all of that into one app:

- Users, media, shares, and lists are models in one database
- Authentication is handled by Devise — no JWT, no session bridges
- Inter-"service" calls are just method calls between models
- One codebase, one test suite, one deployment

The UI is built with [klods-ruby](https://github.com/druewilding/klods-ruby), wired up from the start via the [rails-server-template](https://github.com/druewilding/rails-server-template).

---

## Domain Model

### Users

Standard Devise user: email, password, display name, avatar. Users can add friends (mutual follow, or one-directional — decide later). Every user gets a default **Inbox** list created on registration.

### Media

A centralised record of a URL and its metadata. Write-once, read-many — the same YouTube URL shared by ten people is one `Media` row. Metadata (title, thumbnail, duration, channel) is extracted on creation (initially synchronously; background job in Phase 2).

Platforms supported initially: YouTube, generic URL.

### Shares

A directed edge: _user A shares media X with user B_ (or with themselves for "save to my list"). Has a status: `pending`, `watched`, `archived`. A share with `from_user == to_user` is a self-save.

### Lists

User-owned collections. Every user has a default Inbox list (auto-created). Users can create additional named lists. A `ListItem` ties a `Media` record to a `List`, optionally referencing the `Share` it came from.

---

## Database Schema

One PostgreSQL database. All tables in one schema.

```ruby
# users — managed by Devise
create_table :users do |t|
  # Devise columns (email, encrypted_password, etc.)
  t.string  :display_name
  t.string  :avatar_url
  t.timestamps
end

# friendships — symmetric join
create_table :friendships do |t|
  t.references :user,   null: false, foreign_key: true
  t.references :friend, null: false, foreign_key: { to_table: :users }
  t.string  :status, default: "pending"   # pending, accepted
  t.timestamps
end

# media — centralised, write-once
create_table :media do |t|
  t.string  :url,            null: false
  t.string  :normalized_url, null: false
  t.string  :platform,       null: false   # youtube, generic
  t.string  :title
  t.string  :description
  t.string  :thumbnail_url
  t.integer :duration_seconds
  t.string  :author
  t.string  :youtube_id
  t.datetime :published_at
  t.references :added_by, null: false, foreign_key: { to_table: :users }
  t.timestamps
  t.index :normalized_url, unique: true
  t.index :platform
end

# shares — the core sharing action
create_table :shares do |t|
  t.references :from_user, null: false, foreign_key: { to_table: :users }
  t.references :to_user,   null: false, foreign_key: { to_table: :users }
  t.references :media,     null: false, foreign_key: true
  t.string  :message
  t.string  :status, default: "pending"   # pending, watched, archived
  t.datetime :watched_at
  t.timestamps
  t.index [:to_user_id, :status, :created_at]
  t.index [:from_user_id, :created_at]
end

# lists — user-owned collections
create_table :lists do |t|
  t.references :user, null: false, foreign_key: true
  t.string  :name,       null: false
  t.string  :description
  t.boolean :is_default, default: false
  t.boolean :is_private, default: true
  t.timestamps
  t.index [:user_id, :is_default]
end

# list_items — media within a list
create_table :list_items do |t|
  t.references :list,  null: false, foreign_key: true
  t.references :media, null: false, foreign_key: true
  t.references :share, foreign_key: true   # nullable — direct adds have no share
  t.string  :status, default: "pending"    # pending, watched, archived
  t.boolean :is_read, default: false
  t.datetime :read_at
  t.datetime :watched_at
  t.text    :notes
  t.integer :position
  t.timestamps
  t.index [:list_id, :status, :created_at]
  t.index [:list_id, :is_read]
end
```

---

## Application Structure

Starting from [rails-server-template](https://github.com/druewilding/rails-server-template): Rails 8.1, klods-ruby, haml-rails, importmap, Turbo, Stimulus. Then add:

- `pg` gem for PostgreSQL
- `devise` for authentication
- `image_processing` / `active_storage` if avatars are stored locally (Phase 2)

### Controllers

```
app/controllers/
  application_controller.rb        # before_action :authenticate_user!
  welcome_controller.rb            # GET / — landing page (unauthenticated)
  dashboard_controller.rb          # GET /dashboard — main authenticated view
  media_controller.rb              # POST /media (add URL)
  shares_controller.rb             # CRUD for shares
  lists_controller.rb              # CRUD for lists
  list_items_controller.rb         # PATCH/DELETE items within a list
  users/
    registrations_controller.rb    # override Devise to create default Inbox on signup
  api/v1/
    status_controller.rb           # health check (from template)
```

### Routes

```ruby
Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  root "welcome#index"
  get "/ping", to: "welcome#ping"
  get "/dashboard", to: "dashboard#index"

  resources :media, only: [:create]
  resources :shares, only: [:create, :show, :update, :destroy]
  resources :lists do
    resources :list_items, only: [:create, :update, :destroy]
  end

  namespace :api do
    namespace :v1 do
      get "/status", to: "status#show"
    end
  end
end
```

### Views (using klods-ruby + HAML)

Views use HAML with klods-ruby builders. The layout shell is `application.html.haml`, inherited from rails-server-template.

klods-ruby marks all output as `html_safe` (via `RailsSafety`) so HAML never double-escapes it. All builders are available in every view with no imports needed.

Use `do` blocks to nest components — the indentation mirrors the HTML structure:

```haml
- content_for :title, "Dashboard"
- content_for :sidebar, toc([toc_item(toc_link({ href: "#inbox" }, "Inbox")), toc_item(toc_link({ href: "#share" }, "Share something"))])

= stack({ gap: 6 }) do
  = prose do
    = h2({ id: "inbox" }, "Inbox")
  = prose do
    = h2({ id: "share" }, "Share something")
```

Key views:

| View | Purpose |
|------|---------|
| `welcome/index` | Public landing page — what is WatchThis, sign up / log in |
| `dashboard/index` | Main authenticated view — inbox, recent activity, quick share |
| `lists/show` | All items in a list with filtering |
| `shares/show` | A single share detail view |

---

## Authentication

Devise with email/password. No JWT, no session bridges.

- `before_action :authenticate_user!` on everything except welcome/landing
- `current_user` available everywhere
- Default Inbox list created in `Users::RegistrationsController#create` after super

---

## MVP Build Plan

### Phase 1 — Foundation

1. Create Rails app from rails-server-template (copy or `git clone` then reinitialise)
2. Add `pg`, `devise` to Gemfile
3. Run `rails generate devise:install` and `rails generate devise User`
4. Override registrations controller to create default Inbox list on signup
5. Build database migrations for all tables above
6. Seed with a test user and some sample media

### Phase 2 — Core Flow

7. `Media` model with URL normalisation and basic YouTube metadata extraction (using `yt-dlp` or `youtube-data-api` gem, or just `open-uri` + regex for the YouTube ID at first)
8. `Share` model and `SharesController` — create, update status, destroy
9. `List` + `ListItem` models — CRUD
10. Auto-add incoming share to recipient's Inbox as a `ListItem`
11. `DashboardController` — show inbox items, recent sent shares

### Phase 3 — UI Polish

12. Build out dashboard with klods-ruby cards for each inbox item (thumbnail, title, sender, status)
13. Quick-share form on dashboard (paste URL → select friend → send)
14. List view with filtering by status (pending / watched / archived)
15. Mark as watched — updates both `Share` status and `ListItem` status
16. Move item between lists

### Phase 4 — Enrichment

17. Background job (Solid Queue or Sidekiq) for metadata extraction after media creation
18. Friend system (`Friendship` model, send/accept requests)
19. Email notifications on new share (Action Mailer)
20. Real-time updates for new inbox items (Turbo Streams via Action Cable)

---

## What the Old Architecture Got Right

Worth preserving as the Rails version grows:

- **Media as a write-once repository**: normalise the URL, deduplicate — one row per unique piece of content. Already handled in the schema above with `normalized_url` unique index.
- **Share status lifecycle**: `pending → watched → archived` is clean and should stay.
- **Self-sharing as first-class**: `from_user == to_user` is a valid share — the "save to my list" use case.
- **List as the primary reading surface**: users consume media through lists, not raw shares.

---

## Technical Notes

- **URL normalisation**: strip tracking params, canonicalise YouTube `youtu.be` → `youtube.com/watch?v=`, lowercase scheme/host
- **Platform detection**: check host for `youtube.com` / `youtu.be`; everything else is `generic`
- **Metadata extraction (Phase 1)**: use the YouTube oEmbed API (`https://www.youtube.com/oembed?url=...&format=json`) — no API key required, gives title, thumbnail, author
- **Metadata extraction (Phase 2)**: background job queued on `Media` creation, updates the record in place
- **klods-ruby version**: pin to the same version as klods-js to keep component parity
