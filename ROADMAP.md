# WatchThis — Roadmap

_Share media with friends. A queue for things you want to watch, read, or listen to._

---

## Phase 4 — Friend System ← current

The prerequisite for everything social. Without it, sharing is only self-save.

**Friend connections**
- `Friendship` model: one row per pair, `status: pending → accepted`
- Search by email to find existing users
- Send a friend request → recipient sees pending requests and can accept or decline
- Friends list page shows who you're connected with

**Sharing with a friend**
- On the share detail page: "Send to a friend" section with friend picker + optional message
- Creates a `Share` from you to the selected friend
- Friend receives it in their Inbox automatically (existing `after_create` callback)

**Display names**
- `display_name` column on users — shown in the friend picker and inbox ("Sent by Drue")
- Falls back to email if not set

---

## Phase 5 — Discovery & Access

Making it frictionless to add things and invite people.

**Bookmarklet**
- A browser bookmark that runs JavaScript on the current page
- One click from any page → opens WatchThis with the URL pre-filled
- Snippet to drag to the bookmarks bar, available on a Settings page
- Works in every desktop browser, no extension needed

```javascript
javascript:window.open('https://watchthis.example.com/media/new?url='+encodeURIComponent(location.href),'_blank')
```

**PWA share target (mobile)**
- Add a `share_target` entry to `manifest.json`
- WatchThis appears in the iOS/Android share sheet once added to the homescreen
- No app required — works via progressive web app APIs
- Android PWA: works well; iOS: varies by Safari version

**Email invites for non-users**
- Share to an email address for someone who hasn't signed up yet
- `Invitation` model: `from_user_id`, `email`, `token`, `media_id` (nullable)
- Action Mailer sends a sign-up link with the token embedded
- On registration, `Users::RegistrationsController` checks for pending invitations
  matching the new user's email → auto-accepts friendship + delivers pending shares
- One-time-use token via `SecureRandom.urlsafe_base64`

---

## Phase 6 — Feed & Navigation

Make the inbox feel like a queue, not a list.

**"Next" flow**
- `GET /inbox/next` redirects to the oldest pending item
- After marking watched, redirect to `/inbox/next` instead of back to dashboard
- "Skip →" button on each share page also advances to next
- Dashboard "Start watching →" button links to `/inbox/next` when items are pending
- Feels like tapping through Stories, not managing a spreadsheet

**Swipe feed**
- Cards in the inbox that can be swiped (swipe right = watched, swipe left = skip)
- Stimulus controller for swipe gestures
- Works well on mobile web before any native app is built

---

## Phase 7 — Platform Expansion

Embedded players keep users in WatchThis instead of bouncing away.

| Platform                  | Detection                 | Embed                                     | Status |
| ------------------------- | ------------------------- | ----------------------------------------- | ------ |
| YouTube                   | `youtube.com`, `youtu.be` | `/embed/{id}`                             | ✅ Done |
| Vimeo                     | `vimeo.com`               | `/player.vimeo.com/video/{id}` via oEmbed | Next   |
| Spotify                   | `open.spotify.com`        | Replace path prefix with `/embed/`        | Next   |
| SoundCloud                | `soundcloud.com`          | oEmbed returns iframe HTML directly       | Next   |
| Netflix / Prime / Disney+ | Host match                | Thumbnail + "Watch on Netflix →"          | Later  |

Each new platform: add detection in `Media.normalize`, add `embed_url` branch, add view branch in `shares/show`.

---

## Phase 8 — Enrichment

Polish and social depth.

**Lists view**
- See all your lists, filter items by status
- Move items between lists
- Create custom lists (e.g. "Weekend", "Work stuff", "For Mum")

**Sender attribution**
- Show who sent something in your inbox: "Sent by Drue" with avatar
- `avatar_url` on users (Gravatar as a zero-config default)

**Real-time inbox**
- Turbo Streams via Action Cable
- New items appear in inbox without a page reload
- Requires adding Action Cable and a Redis add-on on Scalingo

**Email notifications**
- Action Mailer: "You have a new share from X" email
- Opt-in via user settings
- Batched digest option (one email per day max)

---

## Long Term — Mobile App

Only once the web version has proven the UX and you're genuinely hitting the ceiling of what the web can do.

**Why not yet**
- PWA share target gets 80% of the native share-sheet benefit
- Two codebases = double the maintenance
- App Store approval adds delay to every release

**Why eventually**
- Native share extension appears naturally in iOS/Android share sheet (no homescreen add step)
- True push notifications (not just email)
- Swipe feed with native gesture physics
- React Native means shared business logic with a JS layer

**Stack when the time comes**
- React Native + Expo
- Same Rails API backend (add `api/v1` routes as needed)
- Expo Router for navigation
- Reanimated for swipe gestures
