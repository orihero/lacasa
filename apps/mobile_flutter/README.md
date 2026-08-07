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
flutter test         # 394 tests
```

Point it at a running `apps/api` (port 4200) via `lib/api/env.dart`.

## Layout

| Path | What |
|---|---|
| `lib/api/` | Typed API layer — client, transport, token storage, models, resources |
| `lib/navigation/` | `route_paths.dart` (every path, declared once), `app_router.dart` (go_router tree), role-aware tab shell |
| `lib/theme/` | Colour/spacing/radii/typography tokens + the liquid-glass surface |
| `lib/shared/` | Widgets and formatters used by more than one feature |
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
| 16 | `profile-agent` | **Built** — the Profile tab root for `role: "agent"`/`"coworker"`; Connected Accounts/Messages push routes that exist but render `PlaceholderScreen` (see gaps) |
| 17 | `saved-listings` | **Built** — `/profile/saved` |
| 18 | `edit-profile` | **Built** — `/profile/edit` |
| 19 | `settings` | **Built** — `/profile/settings` and `/work/settings` |
| 20 | `language-sheet` | **Built** — a bottom sheet, not a route; opened from every Language row |
| 21–38 | the whole Work/CRM tab (dashboard, my-listings, leads, coworkers, connected-accounts, create/edit-listing, delete-confirm, …) | **Not started** |

**Every signed-out surface, plus auth and the whole Profile branch, is now
built.** A visitor can be introduced (onboarding), browse (home, search,
filters, map), open a listing, page through its photos, find an agent, read
their profile and listings, get in touch, sign in or register, and manage
their own profile (saved listings, edit profile, settings, language,
sign-out) — all without touching the Work/CRM tab. What is left is
everything behind an agent/coworker session: the Work tab's dashboard,
listing management, leads, coworkers and their supporting sheets.

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
  nothing in the app uses either capability yet (`create-listing` is unbuilt;
  there is no push plugin here and no device-token endpoint in `apps/api`).
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
  webview. Every one of these says on screen what it actually did.
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
- **`search` and `filter` still have no tests.** Their build agents were cut
  off before writing any, and no pass since has closed it — everything else
  here is covered, including all five screens added most recently.
- **`profile-agent`'s Connected Accounts row and Messages row push registered
  but unbuilt routes** (`/profile/connected-accounts`, `/profile/messages`),
  same as `settings`'s own Connected Accounts row when reached from the
  Profile branch. All three render `PlaceholderScreen` for now — the routes
  exist (`route_paths.dart`'s `profileConnectedAccounts`/`profileMessages`)
  so nothing 404s, but no `connected-accounts`/`messages` screen has been
  built anywhere in this app yet. `/work/connected-accounts` is the same
  story, one tab over.
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
