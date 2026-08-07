# La Casa — mobile app design mockups

Clickable prototypes of the La Casa mobile app. A, B, C and E implement the **same 38 screens** with
the **same seed data**, so the choice between them is a choice of design language, not of scope. D is
the one exception: a narrower, later addition covering **the home feed only**.

`SCREENS.md` is the shared spec they were all built from: navigation model, full screen inventory,
per-screen contents with the real field labels and enum values pulled from the web app and the Prisma
schema, the seed dataset, and the interaction contract.

> **Desktop lives in [`WEB.md`](WEB.md)** — three separate surfaces (`web-user.html`,
> `web-agent.html`, `web-admin.html`) for the buyer marketplace, the agent console and the admin
> control room. They inherit direction E's material language and this file's seed data, and are
> generated from `build/` so no asset is inlined twice.

## The directions

| | File | Lineage | Opens on | Character |
|---|---|---|---|---|
| **A · Listing Board** | `mockup-a-listing-board.html` | Zillow, Redfin, Karrot | Browse feed | Dense marketplace. White + navy ink, one hot orange signal. Condensed grotesque prices, mono spec strips. Edge-to-edge photo cards, sticky filter rail, Map/List pill. |
| **B · Console** | `mockup-b-console.html` | Attio, Linear, Notion | The pipeline | Pro instrument. Graphite, single brass accent, dark-first. Monospace UI, tabular numerals. 44px rows instead of cards, no decorative imagery in the workspace. |
| **C · Concierge** | `mockup-c-concierge.html` | Airbnb, Opendoor, Origin | A curated collection | Premium brokerage. Porcelain green-grey, deep forest + brass. Old-style serif display against humanist sans. Full-bleed heroes, sheet-based navigation. |
| **D · Realti** *(home feed only)* | `mockup-d-realti.html` | [Realti Real Estate UI Kit](https://www.figma.com/design/51fQXjUdoiEAejxb6QUiSb/Real-Estate-App-UI-Kit--Community-?node-id=2-31) (Figma Community) | Browse feed | Consumer marketplace. Navy ink `#252B5C` on `#F5F4F8` fills, one deep-teal accent `#234F68`, lime only on the notification ring. Lato display / Raleway UI / Montserrat numerals, 25px pill radii, photography everywhere. |
| **E · Liquid Glass** | `mockup-e-liquid-glass.html` | iOS 26 / visionOS material; feed structure from D | Browse feed | Glassmorphic consumer app. Near-black ink `#15151B` on porcelain, one magenta accent `#F5439B`. Poppins throughout, 20–28px pill radii. Every control is a translucent, blurred, specular-lit surface; photography carries the screen. |

### D is a partial direction

D was ported from an existing Figma file rather than designed against `SCREENS.md`, and **only the
`Home / Full` frame (`2:2473`) was ported** — there are no other screens, no router, no back stack and
no "All screens" index. Treat it as a visual-language sample, not a prototype. Specific gaps and
deliberate deviations from the source file:

- **Four tabs, not five.** The source frame has Home / Search / Saved / Profile. La Casa's role-based
  **Work** tab (`SCREENS.md` §5) has no equivalent in this design yet and was not invented.
- **No star ratings.** The kit rates every listing; La Casa has no rating field, so that slot carries
  the real `rooms · area` spec instead. No numbers were fabricated.
- **District thumbnails reuse listing photography.** Figma exported empty 181-byte PNGs for the four
  location chips and one agent avatar; the kit's own replacements are Indonesian landmarks, which read
  wrong against Tashkent districts.
- **Promo banners were rewritten** ("One Post, Every Channel" / "New in Yashnobod") — the source
  carried a Halloween sale and a summer-vacation discount, neither of which La Casa has.
- **The header block was cut down.** The source opens with a profile avatar, a two-line "Hey,
  {name}" greeting and a 70px search field, pushing the first listing below the fold. Search moved
  into the header in place of the avatar, and the greeting and search field were dropped, so the
  category chips now sit directly under the header. The kit's decorative background blob went with
  them — sized to a 50px header it read as a grey wedge cutting across the location pill.

### E, and what it borrows from D

E takes **D's feed structure** — one phone, the same outer page chrome, one scrolling home feed built
from the same section stack, and La Casa's own seed data — and rebuilds it in a glass material
language. The other 36 screens are E's own; it covers all 38 of `SCREENS.md` with a full back stack,
role-aware tab bar, sheets and an "All screens" index, like A, B and C.

- **The home feed follows D section for section**: location pill + notifications + search header,
  category chips, promo carousel, Featured Listings rail, Top Districts, Top Agents, Explore Nearby
  grid, tab bar. It carries no star ratings, since La Casa has no rating field; that slot carries the
  real `rooms · area · floor` spec instead. Unlike D the tab bar is the full role-aware set — the
  **Work** tab appears for agent sessions and the Profile tab retargets per session (§1).
- **Icons are [Phosphor](https://phosphoricons.com) via [Iconify](https://iconify.design)**, fetched
  from `api.iconify.design` at build time and inlined into the `window.ICONS` map at the foot of the
  document, so the file needs no network and no icon runtime. Every glyph is painted into a
  `[data-i]` slot at boot; only the 68 the markup still references are inlined. The iOS status bar is
  hand-drawn — no icon set carries a faithful copy of it.
- **Photography is a registry too.** The 22 JPEGs live once each in a `window.PHOTOS` map beside
  `ICONS` and are painted into `[data-ph]` slots at boot, so a photo reused across six screens costs
  its bytes once and the markup above stays readable.
- **The router is data-attribute driven.** A screen declares its kind by class — `tab-root`, `modal`,
  `sheet`, `full`, or nothing for a pushed screen — and the router derives the rest: one back stack
  per tab (so switching tabs and returning lands where you left off), an overlay stack for sheets and
  modals, tab-bar visibility, frosted-strip height and status-bar tint. Controls are wired by
  attribute (`data-go`, `data-back`, `data-fav`, `data-group`, `data-panes`, `data-sw`, `data-chk`,
  `data-eye`, `data-hold`, …), so new markup needs no new JavaScript. The contract is documented at
  the head of the runtime block.
- **The glass is two primitives**, `.g` (over photography, light content) and `.gl` (over the pale UI
  surface, dark content), both driven by theme variables so they re-tint in dark mode. Each composes
  a `backdrop-filter` blur + saturate, a masked 1px refractive rim on `::before`, and a specular
  sheen on `::after`. Elements deliberately overlap the glass — the tab bar sits over the Explore
  grid, the price bar over "Asking price", a frosted strip catches content passing under the clock —
  so the refraction always has something to bend. Photo cards carry a top/bottom scrim underneath
  their glass labels, without which white text on a bright photograph washes out.
- **Photography is Unsplash**, cropped and colour-graded (the promo's sky was warmed to dusk) and
  inlined as JPEG data URIs: 6 of the 8 seed listings, 4 districts, 5 agent portraits, 2 promos, the
  onboarding hero, and a hero plus three interiors for `ad-1001`. The two seed listings without their
  own shot reuse an existing one that fits — `ad-1007` (New-build 4-room in Yashnobod) takes the
  Yashnobod promo photograph, which is the same building at the same price, and `ad-1005` (Two-room
  flat in Mirobod, sold) takes the Mirobod district photograph. No stand-in is used for a listing in
  a different district.
- **Copy is real.** Onboarding runs the three slides from `SCREENS.md` §3.1; every listing, lead,
  agent, notification and dashboard figure comes from §4, and every field label, enum label, error
  string and toast is quoted from §3. Invented for this file only: the `ad-1001` description and its
  Nearby chips, the two promo banners (carried over from D), the per-agent ad counts under the feed
  avatars (§4.3's listing counts), the agent contact details and star ratings on `agents-directory`
  (§3.9 specifies the fields but no values), the lead `source` values, and the publish-status
  timestamps and failure message.
- **`register` carries the realtor-type proposal.** E is the only file with it. Sign-up opens on an
  **"I'm signing up as"** pair of cards — Buyer (default) or Realtor — and choosing Realtor reveals a
  **Solo agent / Agency** toggle; Agency adds agency name, office phone and team size, and the button
  becomes "Create realtor account". `SCREENS.md` §13 documents the fields and what each choice implies
  (agency = owner + coworkers, solo = no team). Nothing behind it exists yet: `role` in the Prisma schema
  is still `user | agent | coworker`, with no solo/agency distinction and no agency entity.
- **The map is drawn, not embedded.** `map-view` and the listing's Location pane render a road grid
  in layered CSS gradients rather than shipping a tile provider, so the file stays offline and
  self-contained. Pins carry the real seed prices.

## Viewing

Open any file in a browser, or use the published artifact links. A, B, C and E each have:

- a **phone frame** (390×844; E is 412×866) that goes fullscreen below 520px viewport width
- a working **back stack**, persistent tab bar, and bottom sheets
- an **"All screens"** overlay in the outer chrome listing every screen, tappable to jump directly
- **prev/next arrows** to walk the whole set in order
- `location.hash` sync, so any single screen is linkable
- light and dark themes, both designed
- a **session switcher** in the outer chrome — Agent / Buyer / Signed out — which adds or removes the
  **Work** tab, retargets the Profile tab, and shows or hides the role-gated rows (§1, §5)

D has the same phone frame, the same 520px fullscreen behaviour and both themes, but only one screen —
so it has no back stack, index or hash routing. Its filter chips are live; nothing else navigates.

Live in E, beyond navigation: the category chips, `register`'s Buyer/Realtor cards and the Solo
agent/Agency toggle nested inside them, every option-pill group and segmented control with
its content panes, the fact rail under **Overview**, every favourite heart, the switches and
checkboxes (the connected-account status switches are deliberately inert per §5, and say so when
tapped), the password reveal toggles, the onboarding pager, the four-step `create-listing` wizard,
the photo gallery's arrows and thumbnail strip, long-press on a kanban card to open **Move to…**, and
every toast the spec quotes.

Everything is self-contained: no external fonts, images, or scripts. In A, B and C property imagery is
CSS gradients and inline SVG. D instead inlines the Figma file's own assets as `data:` URIs — 21 exported
SVG glyphs plus 13 photographs, downscaled to their rendered size and re-encoded (~307 KB) — and the three
Google fonts, subsetted to the ~95 glyphs the screen actually renders (~316 KB). That is why `mockup-d`
is 650 KB against A/B/C's ~240 KB. Its build emits only the assets and font weights the markup still
references, so trimming the screen shrinks the file. E is 800 KB on the same principle: 22 photographs
(~545 KB), Poppins 400/500/600/700 latin-subset (~41 KB), and only the 68 Iconify glyphs the markup
still references (~24 KB). Because both are registries rather than inline attributes, growing from 3
screens to 38 added markup, not assets.

## Screen coverage

**D covers one screen:** home feed — location switcher, notifications, search, category chips, promo
carousel, Featured Listings rail, Top Districts, Top Agents, Explore Nearby grid, tab bar.

**A, B, C and E** cover all 38:

Public: onboarding, permissions primer, home feed, search, filter sheet, map view, listing detail,
photo gallery, agents directory, agent profile, contact sheet, sign in, sign up, signed-out profile.

Account: buyer profile, agent profile, saved listings, edit profile, settings, language sheet,
connected accounts, notifications, messages, delete confirm.

Workspace: statistics dashboard, my ads, add new post (multi-step), update post, select channels,
publish status, leads list, kanban, lead detail, create lead, move lead sheet, coworkers, coworker
detail, create coworker.

## Verification

Rendered in headless Chrome and audited screen-by-screen (all 38 in each file) for horizontal
overflow, content escaping the phone frame, zero-height screens and empty content. Fixes applied
after the first review round:

| File | Defect | Fix |
|---|---|---|
| A | `<button class="card-listing">` contained a nested favorite `<button>`. HTML forbids nested buttons, so Chrome closed the outer button and its open `<div>`s early — 35 of 38 screens, the tab bar and the chrome escaped to `<body>` and rendered full-page-width. | Outer card converted to `div[role="button"][tabindex="0"]` (×24), matching the pattern the map view already used. |
| A | `.chrome__btn svg` had no size rule, so inline SVGs fell back to the default 300×150 and blew the chrome pill to 563px. | Added `.chrome__btn svg { width:18px; height:18px }`. |
| A | Screen count showed `0` — `buildIndex()` only ran when the overlay opened. | Called at boot. |
| A | Row-layout card titles overflowed instead of truncating: `.card-listing__body` is a flex item and could not shrink. | Added `min-width: 0`. |
| A | No status bar, so the notch overlapped 34 screen headers. | Added top padding to `.app-header`. |
| B | `onboarding` had `active` hardcoded while `boot()` routes to `home-feed`; `switchTab` only manages tab-roots, so onboarding never cleared and sat on top permanently. | Removed the stale class. |
| B | Photo gallery: 5-slide flex track with no clipping ancestor — the screen scrolled 1480px sideways. | Added `overflow:hidden` to `[data-gallery]`. |
| B | Role switcher clipped "Coworker" — `flex:1` without `min-width:0`. | Wrapped to a 2×2 grid. |
| C | `data-role-visible` sat on the `<section class="screen">` itself, so `applyRoleVisibility()` wrote an inline `display:none` that beat `.screen.active` — `profile-buyer` and `profile-agent` rendered blank. | Screens excluded from role display-gating; jumping to a role-specific screen now adopts that role. |
| C | Chrome widget was a column flex with a pill radius, so the wide "All screens" button rendered it as a blob. | Switched to a row. |
| D | Favourite buttons rendered as blank white discs. The kit ships two states — a white disc (`Button / Favorite`) with a hairline gradient heart, and a lime disc (`Component 6`) with a **white** heart. The white heart had been paired with the white disc. | Split into `.fav` / `.fav--on`, each pairing the disc and heart the kit intended. |
| D | Dark theme rendered the navy glyphs near-invisible — they are baked into the exported SVGs, so no CSS colour reaches them. | Monochrome glyphs tagged `.mono` and flipped with `filter:brightness(0) invert(1)` in dark. Chips that sit on photography moved to a fixed `--on-photo` token so they do not follow the theme. |
| A, C | **Navigation froze once any overlay opened.** Both routers tracked overlays separately from the base screen, but the "go to a normal screen" path never dismissed the open overlay — so the current-screen lookup kept returning the stale overlay id and prev/next jumped to the same target forever. A stuck on `map-view`, C stuck on `permissions-primer`. | Overlay is now cleared before pushing a non-overlay screen (C's `jumpTo` matched to its own `navTo`, which already did this). |
| E | The Sizes pane leaked into every other tab: `.pane{display:none}` was overridden by the later `.rows{display:flex}` on the same element, so Description rendered with the size rows stacked under it. | `display` moved off `.rows` and onto `.pane.rows.on`. |
| E | Glass labels on photo cards were unreadable — white text on a heavily blurred, brightened pane over a bright interior shot is white on near-white. | Top/bottom scrim added under the overlays (`.scrim::after`), plus a text shadow on the badge, price and district pills. |
| E | Feed content scrolled straight into the status-bar clock. | A frosted `.topfade` strip, masked to fade out, sits under the clock on both scrolling screens. |

Fixes from the round that took E from 3 screens to 38:

| File | Defect | Fix |
|---|---|---|
| E | Modals, sheets and full-screen takeovers rendered *under* the screen they cover — the home feed's cards showed through `onboarding`, `login` and `create-listing`. Sections are absolutely-positioned siblings at `z-index:auto`, so paint order was DOM order, and every overlay that happened to be declared earlier lost. | Overlay screens raised to `z-index:56` — above the tab bar (30) and the frosted strip (45), below the status bar (60). |
| E | Every stacked label/sublabel pair rendered on one line ("Saved Listings4 listings", "LanguageEnglish"). The rows are built from `<span>`s so they can sit inside a `<button>`, and inline spans do not stack. | `display:block` on `.lrow__t`/`.lrow__s` and the seven other span pairs; `.av` too, which was collapsing avatars to a distorted strip wherever it was not already a flex child. |
| E | All four `create-listing` steps rendered at once — the pane rules covered `[data-pane-body]` but nothing hid `[data-step-body]`. | Added the matching `display:none` / `.on` pair. |
| E | The **Work** tab stayed visible for buyer and signed-out sessions. `.tab--work{display:none}` and `.tab{display:flex}` have equal specificity, and `.tab` is declared later. | Hide rule qualified to `.tabbar .tab--work`. |
| E | Tapping **Next** in the wizard threw — `closest('[data-steps]')` returned null because the step indicator is in the header and the buttons are in the body, so neither contains the other. | Falls back to the enclosing screen's indicator. |
| E | The wizard header overlapped the status bar, and `create-listing`'s own frosted strip blurred its title, because raising the modal above the global strip took the strip out from under it. | Taller header variant (`--fh:152px`) plus a local `.topfade` inside that one screen. |
| E | Sheets over a dimming scrim read as grey panels — 62%-opaque white over a darkened backdrop is grey, not white. | Sheets get their own 88% surface, keeping the blur and the refractive rim. |

From the round that added the realtor-type toggle to `register`:

| File | Defect | Fix |
|---|---|---|
| E | Two segmented controls could not coexist on one screen: the pane handler cleared `.on` from *every* `[data-pane-body]` in the screen, so picking Solo or Agency closed the Realtor pane they live in. | Panes are scoped to the enclosing `[data-pane-scope]` when there is one, and a body is only touched by the toggle whose scope it belongs to. The screen-wide default is unchanged, so the other four segmented controls behave exactly as before. |
| E | `register` scrolled into the status-bar clock. It is a `.modal`, and modals paint at `z-index:56` — above the global frosted strip at 45 — the same reason `create-listing` needed its own. | A local `.topfade` inside the screen, as on `create-listing`. |

Verified by rendering `register` in both themes across all three states (Buyer / Realtor+Solo /
Realtor+Agency), scrolled to the foot of the tallest one, plus in-page probes: pane state after each
click, `scrollWidth === clientWidth` on the body in every state, an unchanged `listing-detail`
segmented control, and zero console warnings or uncaught errors.

Navigation is verified by walking every screen with the "next" control and logging the router's
synced hash: A 38/38, B 37/37, C 38/38 distinct screens, no repeats, clean wrap-around. A static
pass confirms every `data-nav`/`data-tab` target resolves and no screen lacks an exit control.
D has no router to walk; it was checked by rendering light and dark, framed and fullscreen, and
measuring in-page that nothing escapes `.phone__screen` horizontally.

E is audited by rendering all 38 screens in both themes and reading them side by side, plus three
static and in-page probes:

- **Reference audit** — every `data-i`, `data-ph`, `data-go`, `data-tab` and `data-hold` resolves;
  no missing icon, no missing photograph, no dangling navigation target, no unused asset. The icon
  registry is pruned to exactly what the markup plus the runtime's click-time swaps still reference.
- **Smoke probe** — walks all 38 screens by hash, then clicks all 122 interactive controls once.
  Reports zero uncaught errors and zero `console.warn` (the runtime warns on any unresolved icon or
  photo key, so a silent run is also an asset check).
- **Navigation probe** — asserts the router's behaviour rather than its markup: pushing
  `notifications` onto Home, switching to Work and pushing `leads-list`, switching back to Home and
  finding `notifications` still on top, returning to Work and finding `leads-list` still on top,
  opening `lead-detail` as a sheet (both it and `leads-list` painted at once), closing the sheet back
  to `leads-list`, then popping to `dashboard`.

> When screenshotting these in headless Chrome, keep the window **wider than 520px** or the responsive
> rule takes the phone fullscreen and the result is not the framed layout. Chrome also floors the
> window at 500px wide, so a narrower `--window-size` silently lays out at 500 and crops the capture —
> which looks exactly like an overflow bug and is not one.

## Known gaps

- OLX cross-posting depends on a Chrome extension in the current architecture. The mockups surface
  this as a constraint on the publish screens; it needs a real answer before the mobile build.
- Jumping directly to a workspace screen via the index or a hash can leave the tab bar highlighting
  the previous tab; navigating there normally is correct.
- No file models the **coworker** session. `SCREENS.md` §5 says a `role: "coworker"` session opens the
  Work tab directly on `my-listings` and skips `dashboard`; every mockup's Work tab is wired to
  `dashboard`, and the coworker branch is documented rather than built. The screens a coworker sees
  all exist — only the entry point differs.
- E's `kanban-move-sheet` draws both of its conditional bodies at once (the call-back time picker and
  the conversation note) so the two states are visible together. In the app only the one matching the
  target column appears; the sheet says so inline.
