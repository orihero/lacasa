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
flutter test         # 159 tests
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
| 3 | `home-feed` | **Built** |
| 4 | `listing-search` | **Built** — reachable at `/search` |
| 5 | `filter-sheet` | **Built** — a bottom sheet, not a route; opened from search's Filters button |
| 7 | `listing-detail` | **Built** — `/home/listing/:id` and `/search/listing/:id` |
| 8 | `photo-gallery` | **Built** — `/photo-gallery`, pushed from `listing-detail`'s hero |
| 11 | `contact-sheet` | **Built** — a bottom sheet; `listing-detail`'s "Submit an application" CTA |
| 6 | `map-view` | **Not started** |
| 1, 2, 9, 10, 12–38 | onboarding, agents, profile, auth, and the whole Work/CRM tab | **Not started** |

**The buyer browse flow now closes end to end**: home or search → listing
detail → photo gallery, and detail → contact. The Work tab (agent CRM) comes
after the remaining buyer screens.

`listing-detail` is declared once per shell branch rather than as one
top-level route, because SCREENS.md §1 lists it under "Pushed (full-screen,
back-stack)" — it keeps the tab bar and stays in the back stack of whichever
tab it was opened from. It takes a `branchPrefix` so the sibling routes it
pushes (`agent-profile`) resolve into that same branch.

### Known gaps

- **`map-view` has no map package.** `flutter_map` + `latlong2` were the chosen
  dependencies (matching `apps/web`'s Leaflet/OSM, no API key needed) but were
  reverted rather than left unused — re-add them when the screen is built.
  `listing-detail`'s Location section is the visible consequence: it shows the
  ad's real coordinates as text and says the map preview is unavailable,
  rather than drawing a decorative grid that reads as a real map.
- **Three platform affordances are stand-ins, not the real thing**, because
  each needs a plugin this app doesn't depend on and adding one is a
  `pubspec.yaml`-plus-platform-config change rather than a screen build:
  `listing-detail`'s share button copies the listing link instead of opening
  the OS share sheet (`share_plus`) — which is also what the source mockup's
  own share button does; the agent block's call button copies the phone number
  instead of dialling (`url_launcher`); and `tour3dLink` is not surfaced at
  all, since embedding a 3D tour needs a webview.
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
  off before writing any, and this pass did not close that — everything else
  here is covered, `listing-detail` and `contact-sheet` included.
