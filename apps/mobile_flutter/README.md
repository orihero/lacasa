# @lacasa/mobile_flutter

The La Casa Flutter client. Talks to `apps/api` like every other surface; the
binding screen spec is [`mockups/SCREENS.md`](../../mockups/SCREENS.md), which
fixes every screen id, label, enum wire value and navigation target so nothing
has to be invented.

This replaced an Expo/React Native prototype (deleted 2026-08-07) — see
`docs/05-migration-plan.md`.

## Running it

```bash
flutter pub get
flutter run          # or, from the repo root: npm run dev:mobile-flutter
flutter analyze      # must be clean
flutter test         # 702 tests
```

Point it at a running `apps/api` (port 4200) via `lib/api/env.dart`.

## Layout

| Path | What |
|---|---|
| `lib/api/` | Typed API layer — client, transport, token storage, models, resources |
| `lib/navigation/` | `route_paths.dart` (every path, declared once), `app_router.dart` (go_router tree), role-aware tab shell |
| `lib/theme/` | Colour/spacing/radii/typography tokens + the liquid-glass surface |
| `lib/shared/` | Widgets and formatters used by more than one feature — including cross-feature-promoted ones like `NavRow`, `LabelledFormField`/`VisibilityToggle`, `FieldLabel` and `ChoiceChipGroup<T>` (see the consolidation note under Known gaps) |
| `lib/features/<name>/` | One directory per feature: `data/` (repository + fixture/live impls), `state/` (Riverpod), `widgets/`, `formatters/` |

`lib/features/home/` is the reference implementation of that layout — copy its
patterns rather than inventing new ones.

## Screen status vs. SCREENS.md

`route_paths.dart` declares **all 38** routes and `app_router.dart` wires the
whole tree, so every tab navigates somewhere. Screens not yet built render
`PlaceholderScreen`, which names the screen rather than faking content.

| # | Screen | Status |
|---|---|---|
| 1 | `onboarding` | **Built** — `/onboarding`; shown once, gated by `app_router.dart`'s redirect |
| 2 | `permissions-primer` | **Built** — `/permissions-primer`; "Allow" is not yet wired to an OS prompt, see gaps |
| 3 | `home-feed` | **Built** |
| 4 | `listing-search` | **Built** — reachable at `/search` |
| 5 | `filter-sheet` | **Built** — a bottom sheet, not a route; opened from search's Filters button |
| 6 | `map-view` | **Built** — `/map-view`, from search's map toggle and `listing-detail`'s Location block |
| 7 | `listing-detail` | **Built** — `/home/listing/:id`, `/search/listing/:id`, `/agents/listing/:id` |
| 8 | `photo-gallery` | **Built** — `/photo-gallery`, pushed from `listing-detail`'s hero |
| 9 | `agents-directory` | **Built** — the Agents tab root, `/agents` |
| 10 | `agent-profile` | **Built** — one route per branch: `/agents/:id`, `/home/agent/:id`, `/search/agent/:id` |
| 11 | `contact-sheet` | **Built** — a bottom sheet; `listing-detail`'s CTA and `agent-profile`'s Message button |
| 12 | `login` | **Built** — `/login`, a root-navigator modal |
| 13 | `register` | **Built** — `/register`, a root-navigator modal |
| 14 | `profile-signed-out` | **Built** — the Profile tab root when signed out |
| 15 | `profile-buyer` | **Built** — the Profile tab root for `role: "user"` |
| 16 | `profile-agent` | **Built** — the Profile tab root for `role: "agent"`/`"coworker"`; Connected Accounts/Messages rows now push the real `connected-accounts`/`messages` screens (§21/§23, built this pass) |
| 17 | `saved-listings` | **Built** — `/profile/saved` |
| 18 | `edit-profile` | **Built** — `/profile/edit` |
| 19 | `settings` | **Built** — `/profile/settings` and `/work/settings` |
| 20 | `language-sheet` | **Built** — a bottom sheet, not a route; opened from every Language row |
| 21 | `connected-accounts` | **Built** — `/work/connected-accounts` and `/profile/connected-accounts` (one screen, two routes); Instagram is fully live-shaped (media/follower/following counts, "Connect Instagram" copies the OAuth URL to the clipboard rather than opening an in-app WebView, per Meta's own restriction), Telegram is a count-only row (no per-channel API), YouTube is a visibly-disabled "Beta" pair (see gaps) |
| 22 | `notifications` | **Built** — `/work/notifications` and `/home/notifications`; fixture data only, contextual taps route to `lead-detail`/`edit-listing`/`publish-status`/`coworker-detail` per §22 (see gaps for the missing backend) |
| 23 | `messages` | **Built** — `/work/messages` and `/profile/messages`; renders §23's own "coming soon, contact leads by phone" banner rather than a chat UI, exactly as specified |
| 24 | `dashboard` | **Built** — `/work/dashboard`, the Work tab's landing screen for `role: "agent"` (coworker sessions skip it, landing on `my-listings` instead, per §24's own note); the chart and the coworker table's Sale count are honest stand-ins (see gaps) |
| 25 | `my-listings` | **Built** — `/work/my-listings`, the Work tab's landing screen for `role: "coworker"`; wires `filter-sheet`'s CRM (`isCrm`) variant for Sort + Status; "infinite scroll" pages a client-side window (see gaps) |
| 26 | `create-listing` | **Built** — `/create-listing`, a root-navigator modal from `my-listings`' "+"; the full §26 field set (Address, Reference, Nearby chips, Additional Info, video) rather than `apps/console`'s reduced one; photo/video pickers are stand-ins (see gaps) |
| 27 | `edit-listing` | **Built** — `/work/edit-listing/:id`, from `my-listings`' edit icon; same field set as `create-listing`, pre-filled, plus the publish section and Delete |
| 28 | `publish-channels-sheet` | **Built** — a bottom sheet, not a route; opened from `create-listing`/`edit-listing`'s per-channel publish buttons |
| 29 | `publish-status` | **Built** — `/work/publish-status/:id`, from `edit-listing`'s "Publish Status" link; Retry on a failed row is visibly present but disabled (see gaps) |
| 30 | `leads-list` | **Built** — `/work/leads` |
| 31 | `leads-kanban` | **Built** — `/work/leads/kanban`, from `leads-list`'s view toggle; card footer omits the coworker avatar/name slot (see gaps) |
| 32 | `lead-detail` | **Built** — a bottom sheet, not a route; opened from `leads-list`/`leads-kanban` row taps and from a lead `notification` tap |
| 33 | `create-lead` | **Built** — `/work/leads/create`, from `leads-list`/`leads-kanban`'s "+ Add new lead" |
| 34 | `kanban-move-sheet` | **Built** — a bottom sheet, not a route; opened by `leads-kanban`'s long-press "Move to…" only when the destination needs a call-back time or a conversation note, per §34 |
| 35 | `coworkers-list` | **Built** — `/work/coworkers`, agent role only; hidden entirely (no "+ Add new coworker") for a SOLO-kind agent, matching the server's own `solo_realtor` 403 |
| 36 | `coworker-detail` | **Built** — `/work/coworkers/:id`; listings-count/last-active are derived client-side, avatar upload is a stand-in (see gaps) |
| 37 | `add-coworker` | **Built** — `/work/coworkers/create`, from `coworkers-list`'s "+" |
| 38 | `delete-confirm` | **Built** — a shared helper (`confirmDelete` in `shared/widgets/delete_confirm.dart`), not a route; called from `edit-listing`/`lead-detail`/`coworker-detail`'s Delete buttons |

**All 38 SCREENS.md screens are now built.** The Work/CRM tab (§21–§38) is
in place behind an agent/coworker session — connected accounts,
notifications, messages, the dashboard, My Ads with its CRM filter sheet,
the full create/edit-listing flow with its publish sheet and status screen,
leads (list, kanban, detail sheet, create, the kanban move sheet) and
coworkers (list, detail, add) — on top of the signed-out surface, auth and
the whole Profile branch already built before it. What is left is not a
missing screen: it's the gaps below — real photo/video/avatar pickers, a
live-mode notifications backend, `url_launcher`-backed OAuth/tel/share
affordances, and the handful of server-side data gaps (agent rating, region
vocabulary, coworker deal counts, a bucketed statistics endpoint) that no
client-side code can close honestly on its own.

`auth_session.dart` is real as of this slice: `signInWithPassword`/
`registerAccount`/`signOut` call through to `AuthRepository`
(`features/auth/`, live/fixture switch), and a persisted token is restored
on launch — see that file's own doc comment for the two-phase (sync
keystore check, then bounded async validation) design.

`listing-detail` is declared once per shell branch rather than as one
top-level route, because SCREENS.md §1 lists it under "Pushed (full-screen,
back-stack)" — it keeps the tab bar and stays in the back stack of whichever
tab it was opened from. It takes a `branchPrefix` so the sibling routes it
pushes (`agent-profile`) resolve into that same branch.

### Known gaps

- **`permissions-primer`'s "Allow" does not raise an OS prompt.** Doing so
  needs `permission_handler` plus `CAMERA`/`READ_MEDIA_IMAGES`/
  `POST_NOTIFICATIONS` in `AndroidManifest.xml` and the matching `Info.plist`
  usage descriptions — declarations deliberately **not** added, because
  nothing in the app uses either capability yet (`create-listing`/
  `edit-listing`'s photo/video pickers and `edit-profile`/`coworker-detail`'s
  avatar pickers are all documented stand-ins with no image-picker
  dependency, see below; there is no push plugin here and no device-token
  endpoint in `apps/api`).
  Requesting permissions for features that do not exist is what store review
  flags. The screen requests through a `PermissionGateway` interface whose
  default answers "unavailable" and whose row says exactly that; whichever
  feature needs the permission first adds the plugin, the manifest entries it
  genuinely needs, and one implementation — and the screen starts working
  unchanged. See `features/permissions/data/permission_gateway.dart`.
- **`map-view` does not cluster pins.** At Tashkent-wide zoom a dense result
  set overlaps. The honest fix is a clustering package, not a hand-rolled
  approximation. The screen does report `"n of m on the map"` whenever some
  results have no coordinates and therefore cannot be drawn at all.
- **No agent `address` or rating.** SCREENS.md §3.9's agent card asks for an
  `address` line and a `"Review: {rating}/5"` star row. Neither exists: `User`
  has no address column and there is no review/rating table anywhere in the
  schema, so `GET /agents` could not send either. Both are omitted rather than
  faked — a hardcoded star rating is a false trust signal, which is the one
  worth refusing outright. Needs a data-model decision upstream.
- **Several platform affordances are stand-ins, not the real thing**, because
  each needs a plugin this app doesn't depend on and adding one is a
  `pubspec.yaml`-plus-platform-config change rather than a screen build:
  `listing-detail`'s share button copies the listing link instead of opening
  the OS share sheet (`share_plus`) — which is also what the source mockup's
  own share button does; every call button (`listing-detail`'s agent block,
  `agent-profile`'s Call action, `profile-agent`'s phone row) copies the phone
  number instead of dialling, and `profile-buyer`'s "Register as Agent" copies
  the Google Form URL instead of opening it (all four want `url_launcher`).
  `tour3dLink` is also not surfaced at all, since embedding a 3D tour needs a
  webview. `connected-accounts`' "Connect Instagram" (§21) is the Work-tab
  instance of the same gap: `InstagramAuthResource.connectUrl()` returns a
  real OAuth URL, copied to the clipboard rather than opened, for the same
  reason — SCREENS.md §21 itself forbids an in-app WebView here regardless
  of tooling, so `url_launcher` is what would close it, not a different
  approach. Every one of these says on screen what it actually did.
- **`language-sheet` stores a preference nothing reads yet.** Picking En/Uz/Ru
  persists and closes, per §3.20 — but there is no ARB catalogue, no
  `flutter_localizations` delegate, and no translated strings: every screen's
  copy is hardcoded English, exactly as SCREENS.md's preamble specifies. The
  sheet says so under the options rather than pretending. Real localisation is
  a separate, large task (extracting every string in `features/`); the provider
  in `features/language/state/` is the seam it plugs into, and that file's doc
  comment lists the concrete steps.
- **`edit-profile`'s avatar uploader cannot pick an image.** §3.18 wants a
  native picker; there is no image-picker dependency, and `permissions-primer`'s
  grant path is itself a documented no-op seam. The avatar renders, the control
  states that changing it isn't available yet, and no dependency was added on
  spec — the same call `permission_gateway.dart` documents at length.
- **`settings`' Notifications toggle has nothing to switch on.** There is no
  push infrastructure anywhere in the project — no messaging plugin here, no
  device-token endpoint in `apps/api`. It persists a preference and says on
  screen that nothing is delivered yet, rather than flipping silently and
  implying a subscription that does not exist.
- **Sign-out clears the session even if the keystore write fails, and says so.**
  `flutter_secure_storage`'s `delete` is a platform channel and can throw; the
  in-memory session is dropped unconditionally, but a stored token that
  survives would sign the account back in on next launch, so the failure is
  surfaced to the user rather than swallowed. See `AuthSessionNotifier.signOut`.
- **`contact-sheet` reports success without sending unless the live switch is
  on.** Its fixture repository accepts and discards, like every other
  feature's — but for a form whose purpose is delivering a message to a
  person, that default is more dangerous than a feed rendering seed data. Any
  build a real user touches needs `--dart-define=LACASA_CONTACT_LIVE_API=true`;
  see `features/contact/data/contact_mode.dart`.
- **The message field is capped at 200 characters, the server allows 2000.**
  SCREENS.md §3.11 says 200 and the tighter of the two is enforced, so the
  three implementations building against the spec agree. Worth reconciling
  upstream.
- **`listing-search` filters and sorts client-side.** There is no server-side
  search or sort endpoint; `search_repository.dart` documents this. Sorting a
  page of results client-side is not the same as sorting the whole set, and
  that will matter once result counts grow.
- **No region/district data.** `filter-sheet`'s city/district selects need the
  203-district vocabulary that lives in `@lacasa/domain`'s `regions.json`,
  which Dart cannot import from npm. It needs its own copy or an API endpoint —
  see `docs/03-data-model.md`.
- **`create-listing`/`edit-listing`'s photo and video pickers, and
  `coworker-detail`/`add-coworker`'s avatar uploader, cannot pick a file.**
  Same call as `edit-profile`'s avatar control above: no `image_picker`/
  `file_picker` dependency was added (`WORK_TAB_CONTRACT.md` §5.2), so there
  is nothing to hand `UploadsResource.presign`/`putBytes` real bytes from.
  Every one of these controls renders `MediaUploadUnavailableNotice` and
  says on screen that upload isn't available in this build yet, rather than
  silently doing nothing. `UploadsResource` itself is real and correct —
  it's one picker plugin (plus the platform permission declarations
  `permissions-primer`'s gap already covers) away from working unchanged.
- **The dashboard's "Ads statistics" chart has no charting library, and in
  live mode is not a daily series.** `GET /statistics/ads` returns two
  period totals (`adsNewCount`/`adsSoldCount`), never a bucketed series —
  there is no server endpoint to plot 12 points against
  (`WORK_TAB_CONTRACT.md` §7.1). Fixture mode hand-paints the real 12-point
  seed series (`workDashboardChartFixture`) with a plain `CustomPainter`,
  matching `apps/console`'s own choice not to pull in a charting library for
  one screen; live mode degrades to `apps/console`'s honest two-bar "Created
  vs Sold" period comparison rather than fabricating a smoother line than
  `/statistics/ads` actually supports. Needs a bucketed statistics endpoint
  upstream before a real time series is possible on either platform.
- **`notifications` has no backend at all.** No `notifications` route, no
  `Notification` model, nothing anywhere in `apps/api`
  (`WORK_TAB_CONTRACT.md` §7.11). Fixture mode renders
  `workNotificationsFixture` as-is; a live implementation would have to
  synthesize notifications from `GET /leads` + `GET /publish/status` +
  `GET /my/ads` + `GET /statistics/coworkers`, which is a real design
  decision (poll cadence, de-duplication, read/unread persistence) left for
  a task of its own, not something this build could fabricate honestly.
- **YouTube and OLX are not actually publishable from this app.**
  `PublishResource` has no direct-publish call for YouTube — only
  `reportYoutube`, a report-back for an upload that happened somewhere else
  entirely, which this app has no mechanism to perform — and OLX
  cross-posting needs the browser extension `apps/console` already ships,
  which has no mobile equivalent (`WORK_TAB_CONTRACT.md` §7.3). Both render
  as visibly-disabled controls with the reason stated on screen
  (`publish-channels-sheet`, `create-listing`/`edit-listing`'s publish
  buttons, `connected-accounts`'s YouTube section) rather than pretending to
  work. Facebook Marketplace is omitted from the publish surface entirely,
  same as `apps/console` — no compliant automation path exists for either.
- **`publish-status`'s Retry on a failed attempt is visibly present but
  disabled.** Neither `publishInstagram` nor `publishTelegram` is designed
  to distinguish "re-attempt this exact failed request" from "publish
  fresh," and `apps/console` permanently disables the same affordance for
  the same reason (`WORK_TAB_CONTRACT.md` §7.3). Wiring it would need a
  dedicated retry endpoint upstream; until then it stays disabled rather
  than risking a silent double-post.
- **Coworkers' "listings count"/"last active"/"Sale count" are derived
  client-side, and one of them is a permanent em dash.** `Coworker` carries
  only 5 fields on the wire — no count, no activity timestamp, no deal
  total (`WORK_TAB_CONTRACT.md` §7.6). Listings count and last-active are
  folded client-side from `AgentAdsResource.myList()` and
  `StatisticsResource.coworkers()`'s raw `ActivityEvent` rows respectively
  — both real, both derived, not fabricated. "Sale count"/"deals closed" has
  no backing data anywhere in the schema — not even an event type to fold —
  so the dashboard's coworker table and `coworkers-list`/`coworker-detail`
  render an honest em dash for it instead of a fabricated number. Needs a
  schema change (a "deal closed" event or column) upstream.
- **`my-listings`'s "infinite scroll" pages a client-side window, not the
  server.** `AgentAdsResource.myList()` has no `limit`/`cursor`/`page` — it
  always returns the complete list (`WORK_TAB_CONTRACT.md` §7.7). The
  screen fetches everything once and reveals it in local pages to keep the
  infinite-scroll feel SCREENS.md §25 asks for, but there is nothing
  server-side actually being paged against; this will matter once an
  agent's ad count grows past what's comfortable to fetch in one call.
- **`leads-kanban`'s card footer has no assigned-coworker identity to
  show.** `Lead` carries no agent-identity field distinct from its own
  `agentId`/`coworkerId` — every lead is already scoped server-side to the
  signed-in agent, so §31's "coworker avatar/name" footer slot has nothing
  real to bind for an agent's own view (`WORK_TAB_CONTRACT.md` §7.8). The
  slot is omitted rather than fabricated; the created-at half of the footer
  is real (`Lead.createdAt`).
- **Two widget shapes each had two independent, near-identical
  implementations before this slice's integration pass** — `profile-buyer`/
  `profile-agent`'s Logout confirm dialog vs. `settings`'s own bespoke one
  (now `shared/widgets/sign_out_confirm.dart`'s `confirmSignOut`, a native
  `AlertDialog.adaptive` — the spec-correct chrome per §1's "native alert
  style" note on `delete-confirm`, which `settings`'s row text explicitly
  invokes), and `features/profile/`'s `ProfileRow` vs. `settings`'s private
  `_SettingsRow` (now `shared/widgets/list_row.dart`'s `ListRow`). A third
  near-duplicate — `features/auth/widgets/auth_form_widgets.dart`'s
  `AuthField`/`AuthVisibilityToggle`/`AuthPrimaryButton` vs.
  `edit_profile_screen.dart`'s private `_FormField`/`_VisibilityToggle`/
  `_PrimaryButton` — was deliberately **not** merged: `auth_form_widgets.dart`
  already documents why it stayed local (nothing outside `login`/`register`
  needed it at the time), and the two field widgets differ enough
  (`onChanged` required vs. optional, 52px vs. 56px buttons) that merging
  them safely is a task of its own rather than a mechanical promotion.
- **A second consolidation pass, once the Work/CRM tab (§21–§38) existed,
  found five more repeats and promoted them to `shared/widgets/`**: the
  13-way duplicated back-arrow app-bar row is now `nav_row.dart`'s `NavRow`
  (a `trailing: List<Widget>` slot covers `create-listing`'s close-icon shape
  and `leads-list`'s two extra actions — the latter's own toggle+add-lead
  pair, only shared by two screens, stayed local as
  `features/leads/widgets/leads_nav_actions.dart` rather than joining
  `NavRow` itself); the byte-identical form-field/visibility-toggle pair
  duplicated across `add-coworker`, `coworker-detail` and `edit-profile` is
  now `labelled_form_field.dart`/`visibility_toggle.dart`'s
  `LabelledFormField`/`VisibilityToggle`; `listing-editor`'s and
  `filter-sheet`'s identical field-label and choice-chip-group widgets are
  now `field_label.dart`'s `FieldLabel` and `choice_chip_group.dart`'s
  `ChoiceChipGroup<T>` (carrying Filter's `allowDeselect` and Listing's
  optional `label` as explicit parameters, not silent behaviour forks).
  `ListingTextField` and `LeadTextField` were deliberately **not** folded
  into `LabelledFormField` alongside them — both carry shape the shared
  widget doesn't (a required-asterisk label, `suffixText`, per-row padding
  tuned for how many fields each form packs in) and forcing one shape onto
  forms that were never the same would just move the duplication into
  `LabelledFormField`'s parameter list instead of removing it.

## Maps

`map-view` and `listing-detail`'s Location preview both draw OpenStreetMap
tiles through `flutter_map` — the same source `apps/web`'s Leaflet map uses,
so neither surface needs an API key or a billing account.

Two things about that are load-bearing rather than incidental:

- **Attribution is a licence term.** `shared/map/map_attribution.dart` is
  rendered by every map surface. `flutter_map`'s own `SimpleAttributionWidget`
  is deliberately not used: it overflows a 390px phone by ~128px and credits
  the rendering library ahead of the data provider.
- **Tiles come from `mapTileLayerProvider`, never an inline `TileLayer`.**
  That is what lets widget tests substitute a plain coloured box; without it
  every map test would fire real requests at OSM's public servers from CI,
  which their usage policy forbids.

## On screenshots

Layout is verified with widget tests that pin `tester.view.physicalSize` to
360/390/430-wide phones and assert no `RenderFlex` overflow — see
`test/phone_width_overflow_test.dart` and the per-screen `layout holds at real
phone widths` groups. Browser screenshots of the web build are **not** a
reliable substitute: the Flutter canvas does not consistently adopt Chrome's
`--window-size`, so a screenshot at a phone viewport shows clipping that is an
artifact of the canvas rather than a real layout fault.
