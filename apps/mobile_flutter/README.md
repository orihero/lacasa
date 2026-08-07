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
flutter test         # 109 tests
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
| 8 | `photo-gallery` | **Built** — `/photo-gallery`, reached via `extra:` |
| 7 | `listing-detail` | **Partial** — data layer only, no screen yet; still a placeholder |
| 6 | `map-view` | **Not started** |
| 1, 2, 9–38 | onboarding, agents, profile, auth, and the whole Work/CRM tab | **Not started** |

Buyer-side screens are being built first; the Work tab (agent CRM) comes after.

### Known gaps

- **`listing-detail` is the missing link in the browse flow.** Search → detail
  and home → detail both still land on a placeholder, which also means nothing
  pushes `photo-gallery` yet. The gallery route degrades to its placeholder
  rather than crashing when it gets no `extra:` payload.
- **`map-view` has no map package.** `flutter_map` + `latlong2` were the chosen
  dependencies (matching `apps/web`'s Leaflet/OSM, no API key needed) but were
  reverted rather than left unused — re-add them when the screen is built.
- **`listing-search` filters and sorts client-side.** There is no server-side
  search or sort endpoint; `search_repository.dart` documents this. Sorting a
  page of results client-side is not the same as sorting the whole set, and
  that will matter once result counts grow.
- **No region/district data.** `filter-sheet`'s city/district selects need the
  203-district vocabulary that lives in `@lacasa/domain`'s `regions.json`,
  which Dart cannot import from npm. It needs its own copy or an API endpoint —
  see `docs/03-data-model.md`.
- **`search` and `filter` have no tests yet.** Their build agents were cut off
  before writing any. Everything else here is covered.
