# @lacasa/console

The real La Casa agent console — the production implementation of the clickable Direction F
prototype in [`mockups/f/`](../../mockups/f/). This is where an agent logs in to manage their own
listings, leads and team, as a working tool against the real API, not a static mockup.

## Relationship to `mockups/f/` and `apps/web`

- **`mockups/f/`** is the preserved design source of truth — `f-console.src.html`, the compiled
  `build/f-components.css`, and `PLAN.md` (the adaptation plan: token decisions, navigation model,
  the 8 screen wireframes, the data-honesty table). This app ports that design to real Tailwind
  components wired to the real API. Nothing under `mockups/` is generated from this app or vice
  versa — it's read, never written, by this codebase.
- **`apps/web`** is a separate, older surface (the public marketplace + realtor dashboard) with its
  own design language (magenta accent, Poppins-on-Inter, React 18). This console deliberately keeps
  its own brand voice (lime accent) rather than matching it — see `mockups/f/PLAN.md` §1's Decision
  6.1. The two apps run side by side during the parity push and share no components; `@lacasa/api-client`
  and `@lacasa/domain` are the only things in common.

## Running it

```bash
npm run dev -w @lacasa/console   # or: npm run dev:console (from the repo root)
```

Serves on **port 5274** (`apps/web` holds 5273). Needs `@lacasa/api` running on **port 4200** — start
it separately with `npm run dev:api`. Login is a real `POST /auth/login` against real seeded agent
credentials; there is no mock-data mode.

Other scripts (all run the same way, `-w @lacasa/console`): `build`, `typecheck`, `lint`, `test`,
`test -- --coverage`.

## Screens: build status

All 8 screens `mockups/f/PLAN.md` §3 wireframes are real and wired against the live API — there is no
longer a `<ComingSoon>` placeholder anywhere in the route table (`src/screens/ComingSoon.tsx` itself
has been removed now that nothing references it):

| Route | Screen | Status |
|---|---|---|
| `/login` | Login | Built |
| `/statistics` | Statistics | Built (§3.1) |
| `/ads` | My ads | Built (§3.2) |
| `/ads/new`, `/ads/:id/edit` | Listing editor | Built (§3.3) |
| `/publish` | Publish status | Built |
| `/leads` | Leads | Built (§3.5) |
| `/leads/kanban` | Kanban | Built (§3.6) |
| `/coworkers` | Coworkers | Built (§3.7) |
| `/accounts` | Connected accounts | Built (§3.8) |

Every screen is a real, routable component reading real `@tanstack/react-query` hooks — not a
blank page — so the rail/topbar/routing and every screen's own content all work end to end today.

## Design rules a future contributor must not break

These come from `mockups/f/PLAN.md` §1 and are encoded as a Tailwind theme in
[`tailwind.config.js`](./tailwind.config.js) (read its own comments — they document the same rules
inline, next to the tokens). They are lint criteria, not suggestions:

- **Accent discipline** — the lime accent (`bg-accent`, `text-accent-text`) marks *exactly one thing
  per screen*. `PLAN.md` §1 names which one thing per screen (e.g. Leads: the "Create lead" CTA +
  New-stage row tint; Coworkers: the "Create coworker" ghost row). The shell `Topbar`'s own
  always-visible "Add new post" CTA is chrome, not screen content, and doesn't count against a
  screen's own budget — *except* on My ads, where "Add new post" is that screen's own accent thing,
  so My ads renders no second copy of it in its own content (`variant="dark"`, not `primary`, on its
  Toolbar/EmptyState buttons — reaching for the accent a second time for the identical action is the
  literal defect this rule exists to catch, not a stylistic nuance).
- **The accent is never a text color.** Ink on lime is `text-accent-text` (dark olive), never
  `text-accent`.
- **Flat depth** — no drop shadows anywhere (no `shadow-sm`/`shadow-md`/etc.). Hover, focus and
  selected states read through color-shift alone (`hover:bg-pill hover:border-hairline`, a selected
  table row is `bg-accent-tint`).
- **One radius scale** — `rounded-full` (pills/avatars/chips) · `rounded-card` (28px panels/modals) ·
  `rounded-kanban` (20px) · `rounded-input` (14px editable fields) · `rounded-chip` (10px tags). No
  other radius value anywhere.
- **One type scale** — the named sizes in `tailwind.config.js` (`text-body`, `text-nav`,
  `text-caption`, `text-title`, `text-h1`, `text-stat`, …). Never an arbitrary `text-[13.7px]`.
- **Colors come from the theme only** — canvas / surface / surface-inner / pill / dark / dark-text /
  ink / ink-2 / hairline / accent / accent-tint / accent-text, plus the ok|warn|err|info|mute (+
  `-soft`) semantic layer. No hex literals in component code.

### Data honesty (`PLAN.md` §4 — the single most important rule)

This is a working tool real agents use all day, not a demo. **Never fabricate a number, metric or
record.** Every value on screen traces to a real API response. Where the prototype shows something
the API genuinely cannot supply yet, the screen renders the amber `<Flag>` banner (`src/ui/Flag.tsx`)
naming exactly what's missing and omits the fake value — it never shows a plausible placeholder.
Known, currently-unfillable gaps (see each screen's own file comment for the specifics): no
activity-feed endpoint, no `ConnectedAccount` model, no `LeadStatus.SUCCESS` member in Prisma yet (so
neither the Kanban board's 6th column nor Coworkers' "Closed" metric can render a real value), and the
`Coworker` payload itself carries no listings/closed/last-active metrics (My ads/Coworkers derive the
two that *are* honestly derivable — listings count and last-active — from ads/statistics the app
already fetches, rather than inventing an endpoint).

## Structure

- `src/shell/` — `AppShell` (the persistent frame), `Topbar`, `Rail`, `Toolbar`, `PageHead`, `nav.ts`
  (the zone/rail model). Mounted once by every authenticated route in `src/routes.tsx`.
- `src/ui/` — the design-system primitives every screen composes: `Button`, `Table`, `Tag`, `Flag`,
  `Modal`, `States` (loading/empty/error), etc. Cross-screen duplicates get promoted here (see
  `Modal.tsx`'s own file comment for one such promotion).
- `src/data/` — the `@tanstack/react-query` hooks every screen reads (`useMyAds`, `useLeads`,
  `useCoworkers`, `usePublish`, `useStatistics`), plus `queryKeys.ts`. A screen-local hook is
  promoted here once a second screen could plausibly want it.
- `src/lib/` — `apiClient` (the configured `@lacasa/api-client` instance), `auth.tsx`
  (`AuthProvider`/`useAuth`/`RequireAuth`), `format.ts`, `labels.ts`, `leadHelpers.ts` (pure `Lead`
  logic — due/overdue callback + wire-status narrowing — shared by Leads, Kanban and Statistics; lives
  here rather than under one screen's folder because three screens depend on it).
- `src/screens/<name>/` — one folder per screen; a built screen owns its own local components,
  derivation helpers and tests.
- `src/test/render.tsx` — the shared test-mount workaround every screen/component test uses in place
  of `@testing-library/react`'s own `render()` (see that file's header for the workspace-wide
  react/react-dom hoisting conflict it works around). Each folder's own `__tests__/testUtils.tsx` is a
  thin re-export of it, kept per-folder as the one obvious place to layer on folder-specific test
  setup (e.g. `screens/coworkers/__tests__/testUtils.tsx`'s added `act()`-wrapping `configure()`).
