# WatchThis — Architecture

_Share media with friends — YouTube videos, articles, music, and more_

---

## Why Rails

The Node.js microservices version had too much infrastructure overhead: four separate services, JWT-to-session bridges, service-to-service HTTP calls, independent databases, and separate test suites per service. The core product idea is simple, and the complexity was getting in the way of building it.

Rails collapses all of that into one app:

- Users, media, shares, lists, and friendships are models in one database
- Authentication is handled by Devise — no JWT, no session bridges
- Inter-"service" calls are just method calls between models
- One codebase, one test suite, one deployment

---

## Domain Model

### Users

Standard Devise user: email, password, optional display name. Every user gets a default **Inbox** list created on registration.

### Media

A centralised record of a URL and its metadata. Write-once, read-many — the same YouTube URL shared by ten people is one `Media` row. Metadata is extracted by a background job after creation.

### Shares

A directed edge: _user A shares media X with user B_ (or with themselves for "save to my list"). Status lifecycle: `pending → watched → archived`. A share with `from_user == to_user` is a self-save.

Creating a Share auto-creates a `ListItem` in the recipient's Inbox via an `after_create` callback.

### Lists

User-owned collections. Every user has a default Inbox list (auto-created on signup). A `ListItem` ties a `Media` record to a `List`, optionally referencing the `Share` it came from.

### Friendships

A connection between two users. Stored as a single row: the requester is `user_id`, the recipient is `friend_id`. Status: `pending → accepted`. The `Friendship.between(a, b)` class method queries both directions. A unique index on `[user_id, friend_id]` enforces no duplicates at the database level.

---

## Database Schema

```ruby
create_table :users do |t|
  # Devise columns (email, encrypted_password, etc.)
  t.string  :display_name
  t.timestamps
end

create_table :media do |t|
  t.string   :url,                null: false
  t.string   :normalized_url,     null: false
  t.string   :platform,           null: false   # youtube, vimeo, spotify, generic
  t.string   :title
  t.text     :description
  t.string   :thumbnail_url
  t.integer  :duration_seconds
  t.string   :author
  t.string   :site_name
  t.string   :youtube_id
  t.datetime :published_at
  t.datetime :metadata_fetched_at
  t.references :added_by, null: false, foreign_key: { to_table: :users }
  t.timestamps
  t.index :normalized_url, unique: true
  t.index :platform
end

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

create_table :lists do |t|
  t.references :user, null: false, foreign_key: true
  t.string  :name,       null: false
  t.boolean :is_default, default: false
  t.boolean :is_private, default: true
  t.timestamps
  t.index [:user_id, :is_default]
end

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

create_table :friendships do |t|
  t.references :user,   null: false, foreign_key: true
  t.references :friend, null: false, foreign_key: { to_table: :users }
  t.string  :status, default: "pending"   # pending, accepted
  t.timestamps
  t.index [:user_id, :friend_id], unique: true
end
```

---

## Platform Support

The `platform` column on `Media` drives metadata fetching and embed decisions.

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

### Adding a New Platform

1. Add detection in `Media.normalize` and a `Media.extract_*_id` class method
2. Add an `embed_url` branch in `Media#embed_url`
3. Add a platform branch in `shares/show.html.haml`

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

## Application Structure

### Controllers

```
app/controllers/
  application_controller.rb        # before_action :authenticate_user!
  welcome_controller.rb            # GET / — landing page (unauthenticated)
  dashboard_controller.rb          # GET /dashboard — main authenticated view
  media_controller.rb              # POST /media (add URL → self-save)
  shares_controller.rb             # GET /shares/:id, POST /shares (share to friend)
  friendships_controller.rb        # index, create, update (accept), destroy
  lists_controller.rb              # CRUD for lists
  list_items_controller.rb         # PATCH/DELETE items within a list
  users/
    registrations_controller.rb    # override Devise to create default Inbox on signup
  api/v1/
    status_controller.rb           # health check
```

### Routes

```ruby
Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  root "welcome#index"
  get "dashboard", to: "dashboard#index"

  resources :media, only: [:create]
  resources :shares, only: [:show, :create] do
    get :metadata_status, on: :member
  end
  resources :friendships, only: [:index, :create, :update, :destroy]
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
- Default Inbox list created in `Users::RegistrationsController#create` after `super`

---

## Metadata Fetching

Media is created immediately; `FetchMediaMetadataJob` runs in the background and updates the record in place. `shares/show` polls `metadata_status` every 500ms via a Stimulus controller (`pending_controller.js`) until `metadata_fetched_at` is set, then reloads the page.

The background job uses the default async adapter in production (jobs run in-process, lost on restart). Acceptable for now; upgrade to Solid Queue or Sidekiq when reliability matters.

---

## Deployment

Scalingo (European Heroku-like PaaS). Git-push deploy, managed Postgres add-on.

Key production requirements:
- `SECRET_KEY_BASE` set as an environment variable (no credentials file)
- `DATABASE_URL` provided automatically by the Postgres add-on
- `RAILS_ENV=production`, `RACK_ENV=production`
- `force_ssl true` in `config/environments/production.rb`
- `postdeploy: bundle exec rails db:migrate` in `Procfile` runs migrations on each deploy

---

## Technical Notes

- **URL normalisation**: strip tracking params, canonicalise YouTube `youtu.be` and `/shorts/` → `youtube.com/watch?v=`, lowercase scheme/host
- **Media deduplication**: always look up by `normalized_url` before creating; one `Media` row per unique piece of content regardless of how many people share it
- **Self-share**: `from_user_id == to_user_id` is the "save to my list" case, not an error
- **Friendship direction**: stored once with the requester as `user_id`; query both directions with `Friendship.involving(user)` or `Friendship.between(a, b)`
- **Turbo redirects**: always use `status: :see_other` on redirects from non-GET actions so Turbo 8 follows them correctly
- **klods-ruby**: all builders available in every HAML view via Railtie; no imports needed
