# La Casa Mobile — Shared Screen Spec

This document is the single source of truth for three independent visual implementations. It fixes every screen id, label, enum value, and navigation target so no designer has to invent one. Copy is English; enum wire values are quoted exactly as they appear in the API/webapp — display labels are the human-readable text designers should render.

**Formatting conventions (apply everywhere):**
- Price display is standardized to `$ {price}` for `category: "sale"` and `$ {price}/month` for `category: "rent"` (this consolidates the web app's three inconsistent formats — `$`, `y.e`, `{priceType}` — into one rule for mobile).
- Dates: `DD.MM.YYYY | HH:MM` (en-GB style, matches web's `formatCreatedAt`).
- Phone numbers: Uzbekistan format only, validated against `^\+998\d{9}$`.
- Ad id badges: `#` + first 5 characters of the UUID.
- Two known web bugs are explicitly **fixed** in this spec (call this out to designers as intentional deviations, not omissions): (1) the map default center is Tashkent (`41.2995, 69.2401`), not the web app's leftover Coventry, UK default; (2) `listing-detail`'s map pin uses the ad's real coordinates, not dummy data; (3) the misspelled empty-state "Not fount post" is corrected to "No listings found" everywhere.

---

## 1. Navigation model

**Bottom tab bar is role-aware — one app, two modes:**
- **Signed-out or `role: "user"` (buyer):** 4 tabs — **Home**, **Search**, **Agents**, **Profile**.
- **Signed-in `role: "agent"` or `role: "coworker"`:** 5 tabs — **Home**, **Search**, **Work**, **Agents**, **Profile**.

One-line justification: the **Work** tab is the entire authenticated CRM (dashboard, listings, leads, coworkers) folded into a single tab that only materializes for agent/coworker sessions, so the same binary serves anonymous browsers and working agents without a second app or a mode switch.

| Tab | Web features it hosts |
|---|---|
| Home | `/` (landing pitch, condensed) + `/ads` (browse feed) |
| Search | `/list` (results), `SearchBar`, `Filter`, `Map` |
| Work (agent/coworker only) | `/profile` dashboard, `AdsList`/`AdsAdd`/`AdsEdit`, `LeadList`/`LeadKanbanList`/`LeadAdd`/`LeadUpdate`, `CoworkerList`/`CoworkerAdd`/`CoworkerUpdate` |
| Agents | `/agents`, `/agent/:id` |
| Profile | `/profile` (buyer branch), `/updateProfile`, `ProfileSetting`, login/register entry |

**Pushed (full-screen, back-stack) screens:** `listing-detail`, `agent-profile`, `edit-profile`, `settings`, `connected-accounts`, `saved-listings`, `my-listings`, `edit-listing`, `publish-status`, `leads-list`, `leads-kanban`, `create-lead`, `coworkers-list`, `coworker-detail`, `add-coworker`, `dashboard`, `notifications`, `messages`.

**Modal (full-screen takeover, explicit dismiss, tab bar hidden):** `onboarding`, `login`, `register`, `create-listing`, `permissions-primer`.

**Bottom sheet (swipe-to-dismiss, partial height):** `filter-sheet`, `contact-sheet`, `publish-channels-sheet`, `lead-detail`, `kanban-move-sheet`, `language-sheet`, `delete-confirm` (native alert style).

**Full-screen modal (no chrome):** `photo-gallery`, `map-view`.

---

## 2. Screen inventory

| # | screen id | Display name | Parent / entry point | Job |
|---|---|---|---|---|
| 1 | `onboarding` | Onboarding | App first launch | 3-slide pitch carousel, skippable, sets up signed-out browse mode |
| 2 | `permissions-primer` | Allow Access | Before first photo upload / push opt-in | Requests camera/photo-library + notification permissions |
| 3 | `home-feed` | Home | Home tab | Marketing hero (signed-out) + browse feed of listings |
| 4 | `listing-search` | Search | Search tab | Search bar, recents, sort, results list (merges web `/list`) |
| 5 | `filter-sheet` | Filters | From `listing-search` / `my-listings` toolbar | Full listing attribute filter form |
| 6 | `map-view` | Map | From `listing-search` map toggle | Pin map of current result set |
| 7 | `listing-detail` | Listing | Any listing card tap | Full property detail, agent block, apply/save CTAs |
| 8 | `photo-gallery` | Gallery | `listing-detail` photo tap | Full-screen swipeable lightbox |
| 9 | `agents-directory` | Agents | Agents tab | List of all agents |
| 10 | `agent-profile` | Agent Information | Agent card tap | Public agent profile + their active listings |
| 11 | `contact-sheet` | Contact Us | Footer/CTA links, "Submit an application" | Name/phone/message contact form |
| 12 | `login` | Sign In | Profile tab (signed out), "Sign in" links | Email/password login |
| 13 | `register` | Sign Up | `login` link, Profile tab | Full name/phone/email/password signup |
| 14 | `profile-signed-out` | Profile | Profile tab, signed out | Sign in/up prompt + language/contact |
| 15 | `profile-buyer` | Profile | Profile tab, `role: "user"` | Buyer account, saved listings, register-as-agent |
| 16 | `profile-agent` | Profile | Profile tab, `role: "agent"`/`"coworker"` | Identity block + settings entry (mobile analog of web Sidebar header) |
| 17 | `saved-listings` | Saved Listings | `profile-buyer` | Grid of saved/liked listings |
| 18 | `edit-profile` | Edit Profile | Profile screens | Avatar + fullName/phone/email/password form |
| 19 | `settings` | Settings | `profile-agent` | Language, notifications, connected accounts, logout |
| 20 | `language-sheet` | Language | Navbar-equivalent, `settings`, `profile-signed-out` | En/Uz/Ru picker |
| 21 | `connected-accounts` | Connected Accounts | `settings` (agent only) | Instagram/Telegram/YouTube connection management |
| 22 | `notifications` | Notifications | Bell icon (any header) | Notification feed |
| 23 | `messages` | Messages | `profile-agent` | Placeholder — web's Chat is a static mock, never wired |
| 24 | `dashboard` | Statistics | Work tab default (agent) | Ads/coworker statistics + charts |
| 25 | `my-listings` | My Ads | Work tab | Agent/coworker's own listings table |
| 26 | `create-listing` | Add New Post | `my-listings` "+" | Multi-step listing creation |
| 27 | `edit-listing` | Update New Post | `my-listings` row edit icon | Edit existing listing + publish status |
| 28 | `publish-channels-sheet` | Select Channels | `edit-listing`/`create-listing` publish buttons | Channel picker before publishing |
| 29 | `publish-status` | Publish Status | `edit-listing`, `notifications` | Per-channel publish status grid |
| 30 | `leads-list` | Leads | Work tab | Table view of leads |
| 31 | `leads-kanban` | Kanban | `leads-list` view toggle | Kanban board of lead pipeline |
| 32 | `lead-detail` | Lead | Row/card tap on `leads-list`/`leads-kanban` | View/edit one lead (sheet, replaces web Drawer) |
| 33 | `create-lead` | Create Lead | `leads-list`/`leads-kanban` "+" | New lead form |
| 34 | `kanban-move-sheet` | Move Lead | Drag/long-press into `need_to_call_back`, `rejected`, `accepted` | Captures call time or conversation note |
| 35 | `coworkers-list` | Coworkers | Work tab (agent only) | Table of coworkers |
| 36 | `coworker-detail` | Update coworker | `coworkers-list` row tap | View/edit/delete one coworker |
| 37 | `add-coworker` | Create coworker | `coworkers-list` "+" | New coworker form |
| 38 | `delete-confirm` | Delete? | Delete buttons on `edit-listing`/`lead-detail`/`coworker-detail` | Destructive-action confirm alert |

---

## 3. Screen contents

### 1 · `onboarding`
No header, full-bleed slides, dot pagination, "Skip" top-right on every slide.
- Slide 1 — "Manage every listing in one place" / "Keep all your listings organized and easy to access, all in one app."
- Slide 2 — "Share to every channel at once" / "Publish to Instagram, Telegram and more without leaving the app."
- Slide 3 — "Track leads from first contact to close" / "Sort and follow up on every inquiry so nothing slips through."
- Final slide button: **"Get Started"** → `home-feed`. Skip → `home-feed`.

### 2 · `permissions-primer`
Header: "Allow La Casa to…"
Rows: "Camera & Photos" — "To add photos to your listings and profile avatar"; "Notifications" — "To alert you about new leads and publish status."
Buttons: **"Allow"** (per row, triggers OS prompt), **"Not now"**. Footer button **"Continue"** → returns to the screen that triggered it.

### 3 · `home-feed`
Header: La Casa logo (left), bell icon → `notifications`, avatar or **"Sign In"** text (signed-out) → `login`.
- Embedded 3D tour banner, label "Live 3D Tour" → tap opens `photo-gallery` in tour mode.
- Section "Latest Listings" — horizontal rail of Listing Cards (see shared component below).
- Button **"View More"** → `listing-search` (unfiltered results already loaded).
- Signed-out only: banner "Are you a real estate agent? Manage your listings, leads and team in one app." button **"Get Started"** → `register`.
- Empty state: "No listings available yet."

**Shared Listing Card component** (used on `home-feed`, `listing-search`, `agent-profile`, `saved-listings`, `map-view` pin preview): thumbnail photo; badge **"Sale"**/**"Rent"**; price (`$ {price}` or `$ {price}/month`); title (truncated); `{district}, {city}`; stat row — `{rooms} room`, `{area} m²`, `{storey}/{floors}`. Tap → `listing-detail`.

### 4 · `listing-search`
Header: search input, placeholder "Search city, district, or title", cancel button.
"Recent Searches" chip row with **"Clear"** link (mobile-only, local storage).
Toolbar: **"Filters"** button (badge = active filter count) → `filter-sheet`; map icon → `map-view`; inline Sort control — **"Highest price"** (`highestPrice`) / **"Lowest price"** (`lowestPrice`) / **"Newest"** (`newest`).
Results: vertical Listing Card list, infinite scroll. Empty state: "No listings match your search."

### 5 · `filter-sheet`
Sheet title "Filters", close "X".
- **City** — select, options from `regions.json` regions.
- **District** — select, disabled until City chosen, cascaded options.
- **Category** — select: **"Rent"** (`rent`) / **"Sale"** (`sale`).
- **Type** — select: **"Residential"** (`residential`) / **"Nonresidential"** (`nonresidential`).
- **Rooms** — select: `1`–`6`.
- **Min. Total area** / **Max total area** — number inputs, placeholders "20"/"40", suffix "m²".
- **Min price** / **Max price** — select from ladder: `100,000` / `500,000` / `1,000,000` / `5,000,000` / `10,000,000` / `30,000,000` / `50,000,000` / `100,000,000` / `500,000,000`.
- **Furniture** — select: **"With furniture"** (`withFurniture`, default) / **"Without Furniture"** (`withoutFurniture`).
- **Repair** — select: **"Not repaired"** (`notRepaired`, default) / **"Normal"** (`normal`) / **"Good"** (`good`) / **"Excellent"** (`excellent`).
- **Storey** — number input, placeholder "5".
Buttons: **"Reset"** (text) / **"Apply Filters"** (filled, shows live count e.g. "Apply Filters (3)").
CRM variant (opened from `my-listings`) appends: **Sort** (same 3 options) and **Status** — **"Active"**/**"Sold"**/**"Draft"**.

### 6 · `map-view`
Header "Map", back arrow → `listing-search`, list-icon toggle back to list.
Map centered on Tashkent (`41.2995, 69.2401`), pins per result. Tap pin → mini preview card (thumbnail, title, price, `{rooms} room`) → tap → `listing-detail`.
Floating button **"Filters"** → `filter-sheet`.

### 7 · `listing-detail`
Header over photo: back arrow, share icon (native OS share sheet), heart/save icon — shown only if `role != "agent"`, toggles `saved-listings` membership.
Photo/video carousel, or embedded 3D tour iframe if `tour3dLink` present — tap → `photo-gallery`.
Title (h1). Address row: pin icon + `{district}, {city}`. Price (`$ {price}` / `$ {price}/month`).
Agent block (tap → `agent-profile`): avatar + `fullName`.
Info tags: **Type**: "Residential"/"Nonresidential"; **Category**: "Sale"/"Rent"; **Repair**: "Not repaired"/"Normal"/"Good"/"Excellent"; **Furniture**: "With furniture"/"Without Furniture".
**Description** section — free text.
**Additional Information** — dynamic key/value chip list.
**Sizes** — Area `{area} m²`, Rooms `{rooms} room`, Floor `{storey}/{floors}`.
**Nearby Places** — dynamic chip list.
**Location** — map pin at the listing's real coordinates.
Buttons: **"Submit an application"** (primary, full-width) → `contact-sheet` pre-filled with listing title + agent; **"Save the Place"** (only if `role != "agent"`).

### 8 · `photo-gallery`
Full-screen, no chrome. Horizontal swipe between photos, page-dot indicator + `{n}/{total}` counter, pinch-to-zoom, bottom thumbnail strip (tap to jump). Close "X" top-left → back to `listing-detail`.

### 9 · `agents-directory`
Header "Agents". List of Agent Cards: avatar; `fullName` (bold); `phoneNumber`; `email`; `address`; **"Review: {rating}/5"** star row; **"Ads: {adsCount}"**. Tap → `agent-profile`. Empty state: "No agents found."

### 10 · `agent-profile`
Header "Agent Information", back arrow.
Info block: **"Full name: {fullName}"**, **"E-mail: {email}"**, **"Phone: {phone}"**, avatar top-right; call icon → `tel:` link; message icon → `contact-sheet` pre-filled.
Section "Ads List" — grid of Listing Cards for this agent. Empty state: "No listings found."

### 11 · `contact-sheet`
Sheet title "Contact Us", subtitle "We welcome all your concerns, issues, and suggestions. Feel free to get in touch with us at your most convenient time."
Fields: **"Full name"** (text), **"Phone"** (text, `^\+998\d{9}$`), **"Message"** (textarea, max 200 chars).
Validation: empty name/phone → "Required fields are not filled"; bad phone → "Invalid phone number format"; success toast "Message sent successfully."
Button: **"Send message"**. Close "X".

### 12 · `login`
Fields: **"Email"** (text), **"Password"** (password). Button **"Sign in"**. Link: "Don't you have an account?" → `register`.
Errors: "Invalid email or password" (401) or the server's validation message (400).
Success → dismiss to `home-feed`, toast "User successfully logged in."

### 13 · `register`
Fields: **"Full name"**, **"Phone number"** (tel), **"Email"**, **"Password"**. Button **"Sign up"**.
Errors: "Email is already registered" (409) or server validation message. Full-screen spinner while submitting.
Success → dismiss to `home-feed`, toast "User successfully created." New account role is `"user"`.

**Account type (mocked in E only; built in the API and the web app).** Above the fields,
**"I'm signing up as"** — two cards,
**"Buyer"** (default) or **"Realtor"**. Choosing Realtor reveals **"Realtor type"**: **"Solo agent"**
(default) or **"Agency"**, and swaps the button to **"Create realtor account"**.

- *Solo agent* — no extra fields. Own listings and leads; the Coworkers screen (§35) stays hidden.
- *Agency* — **"Agency name"** (required; shown on the team's listings in place of the agent's own name),
  **"Office phone"** (optional, same `^\+998\d{9}$` rule), **"Team size"** (`Just me for now` / `2–5` /
  `6–15` / `16+`). The account is the agency **owner**: it may invite coworkers, assign leads to them, and
  see team-wide statistics; coworkers see only what they are assigned.
- Either realtor choice carries the note "Realtor accounts are verified before the Work tab unlocks. We'll
  call the number above — usually within one business day," and creates the account with a pending
  verification state rather than an immediate `role: "agent"`. Toast: "Account created. We'll verify your
  realtor profile shortly."

This replaces the Google-Form path for new signups. §15's **"Register as Agent"** row still covers an
existing buyer upgrading in place, and is unchanged.

Built as of 2026-08-03: `users.realtor_kind` / `realtor_status` / `agency_name` / `office_phone` /
`team_size` (migration `20260803120000_realtor_kind`), `POST /auth/register`'s optional `realtor`
block, the `realtor` object on every serialized user, a 403 on `POST /coworkers` for a solo agent,
and the web app's `/register` form. `role` still remains `"user" | "agent" | "coworker"` — an
approved application is what promotes an account to `"agent"`, and approving is still a manual,
back-office act with no route of its own. The mobile app has no auth screens yet, so this exists
only in the mockup there.

### 14 · `profile-signed-out`
Header "Profile". Prompt card: "Sign in to save listings, message agents, and manage your business."
Buttons: **"Sign In"** → `login`; **"Sign Up"** → `register`. Rows: **"Language"** → `language-sheet`; **"Contact Us"** → `contact-sheet`.

### 15 · `profile-buyer`
Header "Profile". Info card: avatar, `fullName`, `email`, `phone`.
Rows: **"Saved Listings"** → `saved-listings`; **"Update Profile"** → `edit-profile`; **"Language"** → `language-sheet`; **"Register as Agent"** (opens external Google Form link); **"Logout"** (confirm → signed-out state).

### 16 · `profile-agent`
Header "Profile". Role badge (raw string `"agent"` or `"coworker"`), avatar, `fullName`, phone (`tel:` link).
Rows: **"Edit Profile"** → `edit-profile`; **"Connected Accounts"** (agent only) → `connected-accounts`; **"Settings"** → `settings`; **"Messages"** → `messages`; **"Language"** → `language-sheet`; **"Logout"**.

### 17 · `saved-listings`
Header "Saved Listings", back arrow. Grid of Listing Cards. Empty state: "You haven't saved any listings yet."

### 18 · `edit-profile`
Header "Edit Profile". Avatar uploader (tap → native picker; triggers `permissions-primer` if ungranted).
Fields: **"Full name"** (required, "First name is required"); **"Phone"** (required, `^\+998\d{9}$`, "Invalid Uzbekistan phone number"); **"Email"** (required, "Email is required"); **"Password"** (required only if changing, min 6, "Password must be at least 6 characters", show/hide toggle).
Buttons: **"Cancel"** / **"Save"**. Toast: "Profile successfully updated!" / "Error updating profile: {message}".

### 19 · `settings`
Header "Settings". Rows: **"Language"** → `language-sheet`; **"Notifications"** toggle (mobile-only); **"Connected Accounts"** (agent only) → `connected-accounts`; **"About"**; **"Logout"** (red, → `delete-confirm`-style confirm).

### 20 · `language-sheet`
Sheet title "Language". Radio options: **"En"** / **"Uz"** / **"Ru"**. Selecting applies immediately and closes.

### 21 · `connected-accounts`
Header "Connected Accounts", back arrow.
- **"Create Instagram post"** read-only status toggle (on if ≥1 account). Connected account cards: avatar, `username`, **"Posts {media_count}"**, **"Followers {followers_count}"**, **"Following {follows_count}"**, per-card **"Disconnect"** button. Button **"Connect Instagram"** — opens the OS system browser / Custom Tabs / SFSafariViewController (never an in-app WebView, per Meta OAuth restrictions).
- **"Create Telegram post"** read-only toggle (on if `tgChatIds` present). Channel cards: avatar, `username`, `title`, **"Members {members_count}"** (no disconnect action).
- **"Create Youtube post"** read-only toggle. **"Add account"** button (native Google Sign-In SDK), **"Sign out"** button. Tagged "Beta."
- OLX / Facebook: no connect row (no persistent account concept exists in web either).
Toasts on OAuth return: "Instagram account connected!" / "Instagram connection failed — please try again."

### 22 · `notifications`
Header "Notifications", back arrow. Rows: icon, title, body, relative time, unread dot (seed data in §4). Tap routes contextually: lead notification → `lead-detail`; publish notification → `publish-status`; sold notification → `edit-listing`; coworker activity → `coworker-detail`. Empty state: "No notifications yet."

### 23 · `messages`
Header "Messages". Banner: "Messaging is coming soon. For now, contact leads by phone." (Web's Chat component is a static, unwired mock — this screen intentionally stays a placeholder.)

### 24 · `dashboard`
Header "Statistics". Time-range selector: **"All"** (`all`) / **"This month"** (`thisMonth`, default) / **"This week"** (`thisWeek`) / **"Today"** (`today`).
Stat cards: **"Ads created"** `{adsNewCount}`, **"Ads sold"** `{adsSoldCount}`.
Chart "Ads statistics" — area chart, series **"Created"** / **"Sold"** over time buckets (see §4 for seed series). *(Mobile spec fix: this must be wired to the real `/statistics/ads` bucketed data — the web version is `Math.random()` mock data.)*
Section "Coworker statistics" — bar chart per coworker (**"Ads count"** / **"Lead count"** / **"Sale count"**) plus a list with the same columns: **"Coworkers"** / **"Ads count"** / **"Lead count"** / **"Sale count"**. Tap coworker row → `coworker-detail`.
Note: coworker sessions skip this screen — Work tab opens directly on `my-listings` for `role: "coworker"`.

### 25 · `my-listings`
Header "My Ads". Toolbar: **"Filter"** → `filter-sheet`; **"+"** (Create New Post) → `create-listing`.
Rows: thumbnail; `#{id}`; Created At; City; Status pill (**"Active"**/**"Sold"**/**"Draft"**); Author; `{rooms} room`; `{area} m²`; edit icon → `edit-listing`.
Row tap (outside thumbnail/edit) → `listing-detail`. Empty state: "Ads not found." Infinite scroll (mobile substitute for the web's 10/25/100 pagination).

### 26 · `create-listing`
Header "Add New Post". Step indicator: "1 Basics · 2 Details · 3 Photos · 4 Publish."
- **Step 1 Basics** — Title (required "Title is required"); City select (required "City is required"); District select, disabled until City (required "District is required"); Address (required "Address is required"); Reference/orientation (required "Reference is required").
- **Step 2 Details** — Type: **"Residential"** (`residential`, default) / **"Nonresidential"** (`nonresidential`); Category: **"Rent"** (`rent`) / **"Sale"** (`sale`); Repair: **"Not repaired"** (`notRepaired`, default) / **"Normal"** (`normal`) / **"Good"** (`good`) / **"Excellent"** (`excellent`); Rooms (number); Area (number, "m²"); Storey (number); Floors (number); Furniture: **"With furniture"** (`withFurniture`) / **"Without Furniture"** (`withoutFurniture`); Hashtags (optional, placeholder "#new #2024"); Price (number) with live currency preview; Price type: **"so'm"** (`uzs`, default) / **"y.e"** (`usd`); Status: **"Active"** (`1`) / **"Sold"** (`2`) / **"Draft"** (`3`); Nearby chip multi-select; Additional Info dynamic key/value rows (**"Delete"** per row, **"Add"** button); Description textarea (required "Description is required").
- **Step 3 Photos** — photo picker, up to 5 images / 5MB each; optional single video up to 70MB.
- **Step 4 Publish** — buttons per connected channel (Instagram/Telegram/YouTube); OLX shown disabled "Not available on mobile"; Facebook Marketplace omitted entirely (no compliant automation path).
Footer: **"Back"**/**"Next"** per step; final step **"Create"**.
Toasts: pending "Creating", success "Successfully created" → `my-listings`; error "Something went wrong."

### 27 · `edit-listing`
Header "Update New Post". Same fields as `create-listing` steps 1–2 pre-filled (no Hashtags field). Existing photos shown in a gallery grid with per-photo delete "X", separate from the new-upload picker.
Publish section: per-channel buttons → `publish-channels-sheet`; link "Publish Status" → `publish-status`.
Buttons: **"Save"** (submit), **"Delete"** → `delete-confirm`.
Toasts: pending "Updating", success "Successfully updated", error "Something went wrong."

### 28 · `publish-channels-sheet`
Sheet title "Select the channels you want to publish to!" List of connected Instagram accounts / Telegram channels, each with a checkbox.
If no Instagram account connected: copy "No Instagram account is connected. You can connect one in Settings, or draft the post yourself." — Publish disabled with that hint.
OLX row disabled: "OLX cross-posting is only available from the desktop app (requires a browser extension)."
Buttons: **"Cancel"** (red outline) / **"Publish"** (filled).
Toasts: "Instagram post published!" / "Instagram publish failed for {usernames}" (or server error message).

### 29 · `publish-status`
Header "Publish Status", back arrow. One row per channel — Telegram / Instagram / YouTube fully shown; OLX shown grayed "Not available on mobile." Status pill: **"PENDING"** / **"DRAFTED_AWAITING_REVIEW"** / **"PUBLISHED"** / **"FAILED"**; externalUrl link "View Post" if present; last-attempt timestamp; error message if `FAILED`.

### 30 · `leads-list`
Header "Leads". Button **"+ Add new lead"** → `create-lead`. View toggle icon → `leads-kanban`.
Rows: `#{id}`; Full name; Phone; Commit; Status pill (**"New"** `new` / **"Could Not Connect"** `could_not_connect` / **"Need To Call Back"** `need_to_call_back` / **"Rejected"** `rejected` / **"Accepted"** `accepted`); Source (right-aligned).
Row tap → `lead-detail`. Empty state: "No leads yet."

### 31 · `leads-kanban`
Header "Kanban". Button **"+ Add new lead"** → `create-lead`. View toggle → `leads-list`.
5 horizontally-scrollable columns, fixed order: **"New"** (`new`), **"Could Not Connect"** (`could_not_connect`), **"Need To Call Back"** (`need_to_call_back`), **"Rejected"** (`rejected`), **"Accepted"** (`accepted`). Column header: colored status pill + card count.
Card: `fullName` (title); phone (bold); `comment`; red pill with callback date/time if status is `need_to_call_back` and `callbackDate` set; red pill with `conversationComment` if status is `rejected`/`accepted`; footer: created-at timestamp + coworker avatar/name.
Tap card → `lead-detail`. Long-press card → "Move to…" action sheet listing the other 4 columns (mobile substitute for HTML5 drag-and-drop); moving into `need_to_call_back` or `rejected`/`accepted` opens `kanban-move-sheet`; moving into `new`/`could_not_connect` moves immediately.

### 32 · `lead-detail`
Sheet header: lead `fullName`, close "X". (Replaces the web's right-side Drawer.)
Fields, pre-filled: Full name; Phone; Email; Budget; Commit (textarea); Status select (same 5 options as above); Source; Coworker select (agent role only, blank default + coworker `fullName`s).
Conditional field: **"Call time"** (datetime picker) — shown only when Status = **"Need To Call Back"**.
Buttons: **"Cancel"**, **"Save"**, **"Delete"** (red) → `delete-confirm`.
Toasts: "Lead successfully updated!" / "Error updating lead: {message}"; delete "Lead successfully deleted!" → `leads-list`.

### 33 · `create-lead`
Header "Create Lead", back arrow.
Fields: Full name (required "First name is required"); Phone (required "Phone number is required", pattern, error "Invalid Uzbekistan phone number"); Email (optional); Budget (optional); Commit (optional textarea); Status select, default **"New"**; Source (optional); Coworker select (agent role only).
Buttons: **"Cancel"** → `leads-list`; **"Save"**.
Toasts: "Lead successfully created!" / "Error creating lead: {message}".

### 34 · `kanban-move-sheet`
Contextual sheet:
- Into **"Need To Call Back"**: title "Enter the next call-back time", field **"Call time"** (datetime picker, placeholder "Select date").
- Into **"Rejected"**/**"Accepted"**: title "Write briefly about the conversation", field **"Commit"** (textarea, min 10 characters).
Buttons: **"Cancel"** / **"Save"** — Save persists the field + new status and moves the card; Cancel leaves the card where it was.

### 35 · `coworkers-list`
Header "Coworkers" (agent role only). Button **"+ Add new coworker"** → `add-coworker`.
Rows: avatar; Full name; Ads count; Phone. Tap → `coworker-detail`. Empty state: "No coworkers yet."

### 36 · `coworker-detail`
Header "Update coworker", back arrow. Avatar uploader.
Fields: Full name (required); Phone (required, pattern, error "Invalid Uzbekistan phone number"); Email (required); Password (optional on edit, show/hide toggle, min 6 if provided).
Buttons: **"Cancel"**, **"Save"**, **"Delete"** (red) → `delete-confirm`.
Toasts: "Coworker successfully updated!" / "Error updating coworker: {message}"; delete "Coworker successfully deleted!" / "Error deleting coworker: {message}".

### 37 · `add-coworker`
Header "Create coworker". Avatar uploader (default placeholder).
Fields: Full name (required "Full Name is required"); Phone (required "Phone number is required", pattern, error "Invalid Uzbekistan phone number"); Email (required "Email is required"); Password (required "Password is required", min 6 "Password must be at least 6 characters").
Buttons: **"Cancel"** → `coworkers-list`; **"Save"**.
Toasts: pending "Uploading", success "Coworker successfully created", error "Something went wrong!"; catch "Error creating coworker: {message}".

### 38 · `delete-confirm`
Native alert. Title: "Delete listing?" / "Delete lead?" / "Delete coworker?" (contextual). Body: "This action cannot be undone." Buttons: **"Cancel"** / **"Delete"** (red, destructive).

---

## 4. Realistic seed data

### 4.1 Property listings (8)

| ID | Title | Price | District (Tashkent) | Rooms | Area | Floor | Type | Deal | Status | Author |
|---|---|---|---|---|---|---|---|---|---|---|
| ad-1001 | Bright 3-room apartment in Chilonzor | $78,000 | Chilonzor | 3 | 65 m² | 4/9 | Residential (`residential`) | Sale (`sale`) | Active (`1`) | Javlon Rustamov |
| ad-1002 | Renovated studio near Yunusobod metro | $350/month | Yunusobod | 1 | 32 m² | 2/5 | Residential (`residential`) | Rent (`rent`) | Active (`1`) | Shahnoza Yoldosheva |
| ad-1003 | Family house with garden in Sergeli | $120,000 | Sergeli | 5 | 140 m² | 1/2 | Residential (`residential`) | Sale (`sale`) | Active (`1`) | Javlon Rustamov |
| ad-1004 | Office space on Amir Temur avenue | $900/month | Mirzo Ulugbek | 4 | 110 m² | 6/12 | Nonresidential (`nonresidential`) | Rent (`rent`) | Active (`1`) | Otabek Yusupov |
| ad-1005 | Two-room flat in Mirobod | $62,500 | Mirobod | 2 | 54 m² | 7/16 | Residential (`residential`) | Sale (`sale`) | Sold (`2`) | Shahnoza Yoldosheva |
| ad-1006 | Retail space near Chorsu bazaar | $1,200/month | Shayxontohur | 2 | 48 m² | 1/1 | Nonresidential (`nonresidential`) | Rent (`rent`) | Active (`1`) | Sardor Abdullayev |
| ad-1007 | New-build 4-room in Yashnobod | $95,000 | Yashnobod | 4 | 88 m² | 12/17 | Residential (`residential`) | Sale (`sale`) | Draft (`3`) | Otabek Yusupov |
| ad-1008 | Renovated 1-room near Yakkasaroy park | $400/month | Yakkasaroy | 1 | 38 m² | 3/5 | Residential (`residential`) | Rent (`rent`) | Active (`1`) | Kamola Rashidova |

### 4.2 Leads (6)

| Name | Phone | Budget | Interest | Stage | Assigned agent |
|---|---|---|---|---|---|
| Dilnoza Yusupova | +998901234501 | $50,000 | 2–3 room apartment, Chilonzor or Yunusobod | New (`new`) | Javlon Rustamov |
| Aziz Karimov | +998933456712 | $80,000 | Family house, Sergeli | Need To Call Back (`need_to_call_back`) | Javlon Rustamov |
| Malika Tosheva | +998977654321 | $1,000/month | Office rental, city center | Could Not Connect (`could_not_connect`) | Shahnoza Yoldosheva |
| Bekzod Nazarov | +998912345678 | $60,000 | 2-room flat, Mirobod | Accepted (`accepted`) | Shahnoza Yoldosheva |
| Ravshan Ismoilov | +998995551122 | $100,000 | 4-room new build, Yashnobod | Rejected (`rejected`) | Javlon Rustamov |
| Nodira Ergasheva | +998911223344 | $400/month | 1-room studio near metro | New (`new`) | Shahnoza Yoldosheva |

### 4.3 Agents / coworkers (5)

| Name | Role | Listings count | Deals closed |
|---|---|---|---|
| Javlon Rustamov | Agent (`agent`) | 24 | 9 |
| Shahnoza Yoldosheva | Agent (`agent`) | 18 | 6 |
| Otabek Yusupov | Agent (`agent`) | 31 | 14 |
| Sardor Abdullayev | Coworker (`coworker`, under Javlon Rustamov) | 11 | 3 |
| Kamola Rashidova | Coworker (`coworker`, under Shahnoza Yoldosheva) | 8 | 2 |

### 4.4 Notifications (5)

1. "New lead: Dilnoza Yusupova is interested in your Chilonzor listing" — 2 min ago
2. "Instagram post published — Bright 3-room apartment in Chilonzor is now live on Instagram" — 1 h ago
3. "Callback reminder — Call Aziz Karimov today at 15:00" — 3 h ago
4. "Listing sold — Two-room flat in Mirobod marked as Sold" — Yesterday
5. "Coworker added a new listing — Sardor Abdullayev created Retail space near Chorsu bazaar" — 2 days ago

### 4.5 Dashboard stat metrics (4)

| Metric | Value |
|---|---|
| Ads created (this month) | 42 |
| Ads sold (this month) | 11 |
| Active leads | 27 |
| Coworkers | 4 |

### 4.6 Dashboard chart — 12-point "This month" series

Today is Day 12 of the current month; totals continue accumulating toward the month-end stat-card figures above.

| Day | Created | Sold |
|---|---|---|
| 1 | 2 | 0 |
| 2 | 1 | 0 |
| 3 | 3 | 1 |
| 4 | 0 | 0 |
| 5 | 2 | 1 |
| 6 | 1 | 0 |
| 7 | 4 | 2 |
| 8 | 1 | 0 |
| 9 | 2 | 1 |
| 10 | 1 | 0 |
| 11 | 3 | 1 |
| 12 | 2 | 1 |

---

## 5. Interaction contract

- **Tab persistence:** each of the 4/5 tabs keeps its own independent back stack and scroll position; switching tabs and returning restores exactly where the user left off.
- **Tab bar visibility:** hidden on all modal screens (`onboarding`, `login`, `register`, `create-listing`, `permissions-primer`) and on full-screen `photo-gallery`/`map-view`; visible everywhere else, including pushed screens.
- **Role-based tab set:** the Work tab appears/disappears immediately on sign-in/sign-out and on role change — no app restart required. `role: "coworker"` opens Work directly on `my-listings` (skips `dashboard`, matching the web's Statistics-hidden-for-coworkers rule).
- **Back stack:** pushed screens respond to native back gesture/button, popping one level at a time. Sheets dismiss via swipe-down or an explicit close control, never via back gesture consuming a stack level. Modals with unsaved form state (`create-listing`, `edit-listing`, `edit-profile`, `create-lead`, `add-coworker`, `coworker-detail`) show a discard-confirmation alert ("Discard changes?" / "Cancel" / "Discard") before dismissing.
- **Filter sheet:** field changes debounce 300ms and update a live result-count preview inside the sheet; the **Sort** field applies immediately without debounce (matches web). Explicit **"Apply Filters"** commits and closes the sheet; **"Reset"** clears all fields without closing.
- **Kanban horizontal scroll:** all 5 columns are laid out in one horizontally-scrollable row that snaps one column per screen-width on phones; each column scrolls vertically independently for its cards. Column order is fixed and never reorderable: New → Could Not Connect → Need To Call Back → Rejected → Accepted.
- **Kanban move (mobile drag substitute):** long-press a card to open a "Move to…" action sheet listing the other 4 column names. Selecting **Need To Call Back** or **Rejected**/**Accepted** opens `kanban-move-sheet` and the move only completes on its **"Save"**; selecting **New** or **Could Not Connect** moves the card immediately, no modal. While a move request is in flight, a loading spinner overlays that one card (not the whole board).
- **Gallery swipe:** horizontal paging swipe between photos with a page-dot indicator and `{n}/{total}` counter; pinch-to-zoom on the current photo; tapping the image toggles the thumbnail strip and counter chrome; swipe down or tap "X" dismisses to `listing-detail`.
- **Create-listing step progression:** a persistent step indicator (1–4) at the top; **"Next"** validates the current step's required fields before advancing (blocked with inline field errors if invalid); **"Back"** never re-validates; the submit action ("Create") only exists on the final step, matching the web's manual-button (non-native-submit) pattern; `edit-listing` uses a real submit ("Save") from any point since all fields are already valid/pre-filled.
- **Toggle states:** the Instagram/Telegram/YouTube switches on `connected-accounts` and `settings` are read-only status indicators (`checked` = has ≥1 connected account) — they are never directly tappable to connect/disconnect; connecting/disconnecting only happens through the explicit buttons beneath each row, exactly matching web's non-interactive `IOSSwitch`.
- **Publish channel sheet:** multi-select checkboxes per connected account; **"Cancel"** discards selection and closes; **"Publish"** is disabled (not hidden) when zero channels are selected or the relevant account isn't connected, and shows the inline hint text described in §3.28 in that state.
- **OLX/Facebook unavailability:** OLX controls are always visible-but-disabled with the fixed hint "OLX cross-posting is only available from the desktop app (requires a browser extension)." Facebook Marketplace is omitted from every mobile screen — no compliant automation path exists on any platform, so there is nothing to gray out.
- **Notification tap-through:** every notification row is tappable and routes to the screen implied by its type (see §3.22); notifications never open a detail screen of their own — they are a dispatch list only.
- **Save actions:** every form's `toast.promise`-style feedback follows a fixed 3-state pattern — pending (e.g. "Creating"/"Uploading"), success (e.g. "Successfully created"), error ("Something went wrong" or the specific server message quoted in §3) — shown as a transient bottom toast, not a blocking alert, except `delete-confirm` and OAuth failures which use native alerts per §3.38/§3.21.
- **Share:** the share icon on `listing-detail` invokes the native OS share sheet (not a custom La Casa screen) with the listing's public URL and title.