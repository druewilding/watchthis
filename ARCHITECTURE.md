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

## Current State (as of 2026-06-28)

### Done

- ✅ Rails app from rails-server-template: Rails 8.1, klods-ruby, haml-rails, importmap, Turbo, Stimulus
- ✅ Devise auth: email/password, custom registrations controller that creates default Inbox on signup
- ✅ All migrations: users, media, shares, lists, list_items — schema fully applied
- ✅ `Media` model: URL normalisation, YouTube detection (watch/shorts/youtu.be), OG metadata via `Net::HTTP`, YouTube via oEmbed
- ✅ `FetchMediaMetadataJob` — queued on media creation, updates record in place
- ✅ `Share` model: after_create callback auto-adds to recipient's Inbox as a `ListItem`
- ✅ `DashboardController`: inbox items with thumbnail, title, author, mark-watched form
- ✅ `MediaController#create`: self-share flow (paste URL → add to own inbox)
- ✅ `SharesController#show`: YouTube embed, OG layout for generic URLs, metadata polling
- ✅ `SharesController#metadata_status`: JSON endpoint for pending Stimulus controller
- ✅ `ListItemsController`: mark watched, destroy
- ✅ `pending_controller.js`: polls metadata_status every 500ms until fetched, then reloads
- ✅ Welcome/landing page, Devise sign-in/register/password views

### Not Yet Built

- ❌ Friend system (`Friendship` model — Phase 4)
- ❌ Sharing with another user (form only does self-share today)
- ❌ `display_name` / `avatar_url` columns on users
- ❌ Lists view with filtering and move-between-lists
- ❌ "Next" feed navigation through inbox (see below)
- ❌ Email notifications
- ❌ Real-time Turbo Stream updates for new items
- ❌ Additional platform support beyond YouTube + generic (see below)
- ❌ Production deployment

---

## Domain Model

### Users

Standard Devise user: email, password, display name (not yet in schema), avatar. Every user gets a default **Inbox** list created on registration.

### Media

A centralised record of a URL and its metadata. Write-once, read-many — the same YouTube URL shared by ten people is one `Media` row. Metadata is extracted by a background job after creation.

### Shares

A directed edge: _user A shares media X with user B_ (or with themselves for "save to my list"). Status lifecycle: `pending → watched → archived`. A share with `from_user == to_user` is a self-save.

### Lists

User-owned collections. Every user has a default Inbox list (auto-created on signup). A `ListItem` ties a `Media` record to a `List`, optionally referencing the `Share` it came from.

---

## Database Schema

```ruby
# users — managed by Devise
create_table :users do |t|
  # Devise columns (email, encrypted_password, etc.)
  t.string  :display_name    # TODO: not yet in schema
  t.string  :avatar_url      # TODO: not yet in schema
  t.timestamps
end

# media — centralised, write-once
create_table :media do |t|
  t.string  :url,                null: false
  t.string  :normalized_url,     null: false
  t.string  :platform,           null: false   # youtube, vimeo, spotify, generic
  t.string  :title
  t.text    :description
  t.string  :thumbnail_url
  t.integer :duration_seconds
  t.string  :author
  t.string  :site_name
  t.string  :youtube_id
  t.datetime :published_at
  t.datetime :metadata_fetched_at
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
  t.datetime :watched_at
  t.text    :notes
  t.integer :position
  t.timestamps
  t.index [:list_id, :status, :created_at]
end

# friendships — Phase 4
create_table :friendships do |t|
  t.references :user,   null: false, foreign_key: true
  t.references :friend, null: false, foreign_key: { to_table: :users }
  t.string  :status, default: "pending"   # pending, accepted
  t.timestamps
end
```

---

## Platform Support

The `platform` column on `Media` drives metadata fetching and embed decisions. Currently `youtube` and `generic`. Expanding this is high value: embedded players keep users in WatchThis instead of bouncing to another site.

### Embeddable Platforms

| Platform       | Detection                 | Embed URL                                                                     | Notes                                                                            |
| -------------- | ------------------------- | ----------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| **YouTube** ✅  | `youtube.com`, `youtu.be` | `https://www.youtube.com/embed/{id}`                                          | oEmbed gives title/thumb/author                                                  |
| **Vimeo**      | `vimeo.com`               | `https://player.vimeo.com/video/{id}`                                         | oEmbed at `https://vimeo.com/api/oembed.json?url=...`                            |
| **Spotify**    | `open.spotify.com`        | Replace `/track/`, `/album/`, `/playlist/`, `/episode/` with `/embed/` prefix | No API key needed; embed height ~152px for tracks, ~380px for playlists/podcasts |
| **SoundCloud** | `soundcloud.com`          | oEmbed returns HTML containing the `<iframe>` directly — use that             | `https://soundcloud.com/oembed?url=...&format=json`                              |

### Non-Embeddable but Worth Detecting

| Platform                | Value                                                                 |
| ----------------------- | --------------------------------------------------------------------- |
| Netflix, Disney+, Prime | Show thumbnail + description from OG tags + "Watch on Netflix →" link |
| Reddit                  | oEmbed available but mainly shows text/image — better to just link    |

### Implementation Plan for New Platforms

Add platform detection in `Media.normalize` and `Media.extract_*_id` class methods. Add `embed_url` branch in `Media#embed_url`. Add platform branch in `shares/show.html.haml`. Vimeo and Spotify are the highest-value additions (video + audio broadens the use case significantly).

Spotify embed example:
```ruby
def embed_url
  case platform
  when "youtube" then "https://www.youtube.com/embed/#{youtube_id}"
  when "vimeo"   then "https://player.vimeo.com/video/#{vimeo_id}"
  when "spotify" then url.sub("open.spotify.com/", "open.spotify.com/embed/")
  end
end
```

---

## "Next" Flow

The core inbox experience should feel like a queue, not a list — you open an item, watch it, and flow straight to the next one without going back to the dashboard.

### Proposed Design

Add `GET /inbox/next` (or `GET /shares/next`) that redirects to the oldest pending item:

```ruby
# routes.rb
get "inbox/next", to: "shares#next_pending"

# shares_controller.rb
def next_pending
  inbox = current_user.inbox
  next_item = inbox&.list_items&.where(status: "pending")&.order(created_at: :asc)&.first
  if next_item
    redirect_to share_path(next_item.share)
  else
    redirect_to dashboard_path, notice: "You're all caught up!"
  end
end
```

On `shares/show`, after marking watched:
- Redirect to `inbox_next_path` instead of `dashboard_path`
- Add a "Skip →" button next to "Mark watched" that also goes to `inbox_next_path`

This gives the feel of moving through a queue. The "Mark watched" action becomes the primary CTA that also advances to the next item — more like tapping through Stories than managing a list.

The dashboard can show a "Start watching" button that links to `/inbox/next` when there are pending items, making the entry point a one-click play.

---

## Application Structure

### Controllers

```
app/controllers/
  application_controller.rb        # before_action :authenticate_user!
  welcome_controller.rb            # GET / — landing page (unauthenticated)
  dashboard_controller.rb          # GET /dashboard — main authenticated view
  media_controller.rb              # POST /media (add URL)
  shares_controller.rb             # show, next_pending
  lists_controller.rb              # CRUD for lists (not yet built)
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
  get "ping",       to: "welcome#ping"
  get "dashboard",  to: "dashboard#index"
  get "inbox/next", to: "shares#next_pending"

  resources :media, only: [:create]
  resources :shares, only: [:show] do
    get :metadata_status, on: :member
  end
  resources :lists do
    resources :list_items, only: [:update, :destroy]
  end

  namespace :api do
    namespace :v1 do
      get "status", to: "status#show"
    end
  end
end
```

---

## Authentication

Devise with email/password. No JWT, no session bridges.

- `before_action :authenticate_user!` on everything except welcome/landing
- `current_user` available everywhere
- Default Inbox list created in `Users::RegistrationsController#create` after super

---

## MVP Build Plan

### Phase 1 — Foundation ✅ Complete

1. ✅ Create Rails app from rails-server-template
2. ✅ Add `pg`, `devise` to Gemfile
3. ✅ Run `rails generate devise:install` and `rails generate devise User`
4. ✅ Override registrations controller to create default Inbox list on signup
5. ✅ Build database migrations for all tables
6. Seed with a test user and sample media (skipped — not blocking)

### Phase 2 — Core Flow ✅ Complete

7. ✅ `Media` model with URL normalisation and YouTube metadata extraction
8. ✅ `Share` model — auto-adds to recipient Inbox via `after_create`
9. ✅ `List` + `ListItem` models
10. ✅ Auto-add incoming share to recipient's Inbox as a `ListItem`
11. ✅ `DashboardController` — show inbox items, quick-share form

### Phase 3 — UI Polish (in progress)

12. ✅ Dashboard cards: thumbnail, title, sender, status
13. ✅ Quick-share form (paste URL → self-save for now)
14. ✅ Share detail page with YouTube embed, metadata polling
15. ✅ Mark as watched
16. ❌ "Next" feed flow (see above)
17. ❌ Move item between lists / list view with filtering

### Phase 4 — Social + Enrichment

18. ❌ Friend system (`Friendship` model, send/accept requests)
19. ❌ Share with a friend (form: URL + friend selector + optional message)
20. ❌ `display_name` + `avatar_url` columns on users
21. ❌ Additional platform support: Vimeo, Spotify
22. ❌ Email notifications on new share (Action Mailer)
23. ❌ Real-time updates for new inbox items (Turbo Streams via Action Cable)

---

## Deployment (Scalingo)

[Scalingo](https://scalingo.com) is a Heroku-like European PaaS — git-push deploy, managed Postgres add-on, no Kubernetes needed.

### One-time setup

**1. Install the CLI**

```sh
curl -O https://cli-dl.scalingo.com/install && bash install
scalingo login
```

**2. Create the app**

```sh
scalingo create watchthis
```

**3. Add PostgreSQL**

```sh
scalingo --app watchthis addons-add postgresql postgresql-starter-512
```

This sets `DATABASE_URL` in the app's environment automatically.

**4. Set required environment variables**

```sh
# Session cookie signing key — no credentials file, so set this directly
scalingo --app watchthis env-set SECRET_KEY_BASE=$(openssl rand -hex 64)

# Tell Rails it's in production
scalingo --app watchthis env-set RAILS_ENV=production
scalingo --app watchthis env-set RACK_ENV=production
```

**5. Add a `Procfile`** (if not already present)

```
web: bundle exec puma -C config/puma.rb
```

**6. Make sure `config/puma.rb` binds to the right port**

Scalingo passes the port via `$PORT`. Rails 8 puma config does this by default, but verify:

```ruby
port ENV.fetch("PORT") { 3000 }
```

### Deploy

```sh
# Add Scalingo as a git remote
scalingo --app watchthis git-setup

# Push to deploy
git push scalingo main
```

Scalingo runs `bundle install`, asset precompile, and starts Puma automatically.

**Run migrations after deploy:**

```sh
scalingo --app watchthis run rails db:migrate
```

Or add a `release` command to `Procfile` to run migrations automatically on each deploy:

```
release: bundle exec rails db:migrate
web: bundle exec puma -C config/puma.rb
```

### Subsequent deploys

```sh
git push scalingo main
```

### Things to check before first deploy

- `config/environments/production.rb`: `force_ssl` should be `true` (Scalingo provides SSL)
- `config/database.yml`: production config should read from `DATABASE_URL` — Rails does this by default
- The background job (`FetchMediaMetadataJob`) runs with the default async adapter in production, which means jobs run in-process and are lost on restart. That's fine for now; add Solid Queue or a Scalingo Redis add-on + Sidekiq when reliability matters

---

## Technical Notes

- **URL normalisation**: strip tracking params, canonicalise YouTube `youtu.be` and `/shorts/` → `youtube.com/watch?v=`, lowercase scheme/host
- **Platform detection**: check host for `youtube.com` / `youtu.be`; everything else is `generic` (Vimeo and Spotify detection to be added)
- **Metadata extraction (sync → async)**: media is created immediately; `FetchMediaMetadataJob` runs in the background; `shares/show` polls `metadata_status` every 500ms via Stimulus until `metadata_fetched_at` is set, then reloads
- **klods-ruby version**: pin to the same version as klods-js to keep component parity
- **What the old architecture got right** (preserved):
  - Media as write-once repository: normalise URL, deduplicate — one row per unique piece of content
  - Share status lifecycle: `pending → watched → archived`
  - Self-sharing as first-class: `from_user == to_user` is the "save to my list" case
  - List as the primary reading surface: users consume media through lists, not raw shares
