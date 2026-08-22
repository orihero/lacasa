# La Casa Console × Direction F — adaptation plan

This folder will hold the **adapted** F-direction desktop console: the Orvion-derived design
language of `mockups/mockup-f-*.html` carrying the **real** 8-screen agent console from
`WEB.md` / `web-agent.src.html`, backed by the actual Prisma schema and seed data.

The three `mockups/mockup-f-*.html` files stay untouched as the historical generic
design-language exploration — `mockups/f/f-console.html` is their adapted successor, the same
relationship `web-agent.html` has to its retired `mockup-a…e` precursors.

**How this plan was made:** three independent adaptation proposals (reference-faithful,
brand-first, agent-workflow-first) were drafted against a shared inventory of the F design
language, the console content spec and the domain model, then judged on fidelity, data honesty,
hour-six ergonomics, buildability and coherence with the three-surface philosophy. The
workflow-first proposal won (41/50), with named grafts from the other two. Open decisions are
in §6 — nothing below them is final until they're answered.

---

## 1. Token decisions

| Token | Final call | Tradeoff being accepted |
|---|---|---|
| Accent | `--accent: #CDF44A` (the reference lime). Magenta was built first per the original Decision 6.1, **rejected by the user on the rendered prototype** (04.08.2026), and reverted. | The console keeps a separate brand voice from the magenta/Poppins marketplace — accepted deliberately; Poppins still ties the surfaces together. Lime is never used as text; the loud card is full lime like the reference's Jane Doe card. |
| Accent-on-tint text | `--accent-text: #2A3505` (dark olive) · `--accent-tint: #E2F79E` for selected rows / ghost rows | — |
| Font | Poppins, replacing Inter (reuse the woff2 already inlined by `build.mjs` — zero new asset cost) | F's 44–52px numerals and `-0.02em` tracking were tuned against Inter's metrics; **numerals must shrink** (cap page titles ~28–32px, pull labels toward the existing console's 11.5–13px working scale). This is a re-tuning pass, not a `font-family` find-replace. |
| Neutrals | Adopt F's warm-grey canvas (`#E9E9E7` / `#F5F5F3` / `#ECECEA` / `#FCFCFA` / `#1E1E1E`), one name each — resolves the three-way `--pill-white`/`--pill` and `--text-primary`/`--text` naming drift between the f-files | Visible deviation from the current console's cooler `--ink:#15151b` system — see Decision 6.1, not silently assumed. |
| Semantic status layer | `ok` (green), `warn` (amber), `err` (red), `info` (desaturated blue or accent-tint), `mute` (grey) — desaturated to stay warm-grey-compatible, never full-strength brand magenta | A *third* category distinct from both neutrals and the brand accent — required because Active/Sold/Draft, Published/Awaiting/Failed and the 5 lead stages are already color-coded and can't all be magenta without breaking the "one thing" law. |
| Radii | One scale: `999px` (pills, avatars, chips), `28px` (all card/panel surfaces — kills the 28/30px drift), `14px` (form pill-inputs — distinguishes "editable" from "navigational" pills), `10px` (table cell chips/tags) | — |
| Shell | One `max-width: 1480px`, one side padding `28px`, one `.body-row` = rail + `.main` — kills the 1520/1460px and 26/28px drift | — |
| Depth | Flat, no drop shadows anywhere, matching F — an explicit change from the current console's `box-shadow:var(--shadow)` hover/active | Hover/focus/selected states must stay legible via color-shift alone (accent-tinted row bg, darker fill) — verify by rendering, not by inspection. |
| Table hairline | Not F's raw `rgba(0,0,0,.07)` — subtle zebra tint via the existing `--surface-inner` token on alternating rows | Reuses an F-native token rather than adding one, but is a deliberate, scoped exception to F's purity for the 4 table-heavy screens. |
| Avatars | No procedural persona-SVG generator anywhere (dropped from f-workspace). Real photo (`User.avatarUrl`) if present, else a deterministic 2-letter initials chip colored by role/stage | Loses f-workspace's most technically bespoke artifact — but named real people (Dilnoza Yusupova, Sardor Abdullayev) in a working tool shouldn't get stock-persona art standing in for them. |

### Accent-discipline rule (lint criterion)

The accent (lime) marks **exactly one thing per screen**. If a build pass reaches for it
anywhere not in this table, the rule is eroding — flag it, don't quietly ship it.

| Screen | The one accent thing | Everything else |
|---|---|---|
| Statistics | "Active leads 27" stat card (full lime) | deltas ok-green/muted; chart series are dark ink with a lime area fill and lime peak dot, per the reference's chart grammar |
| My ads | primary "Add new post" CTA + `ad1001`'s pre-selected row tint | status tags stay ok/warn/err, never magenta |
| Listing editor | primary "Save" + Active toggle when ON | — |
| Publish status | "Retry failed" CTA | status dots ok/warn/err only |
| Leads | "Create lead" CTA + New-stage row accent | stage tags use the fixed 5-color semantic set |
| Kanban | none — the 5-color dot system already carries the semantics | — |
| Coworkers | "Create coworker" ghost-row CTA | — |
| Connected accounts | YouTube "Reconnect" (urgent) only | — |

---

## 2. Navigation model

**Primary nav: a 236px labeled left rail**, replacing F's decorative icon-only rail (whose only
job in all three originals was hiding a support icon via three different hacks). Three groups:

- **Workspace** — Statistics · My ads `8` · Listing editor · Publish status
- **Pipeline** — Leads `27` · Kanban
- **Team** — Coworkers `4` · Connected accounts
- Footer: account-switcher chip — avatar, "Javlon Rustamov", "Agent · Chilonzor", caret (no
  dropdown wired, matches prototype convention).

Row visual = F's `.icon-btn` circle (pill-white bg, hairline border, dark-filled active state)
widened to hold a label; badge counts styled as F's `em` kanban-count-pill.

**Topbar demoted, not discarded**: 3 pills only (Workspace / Pipeline / Team) act as a zone
indicator synced to the active rail group — calmer than F's own 4-pill reference. Global
elements unchanged: search box "Search ads, leads…", bell (heuristic unread dot, §4), gear,
avatar-stack, and a global "Add new post" primary button on **every** screen.

Editor and Publish status remain reachable both from the rail and via row actions on My ads
(pencil → editor, broadcast → publish status) — no new modal/overlay pattern.

**Documented alternative (not built)**: a two-tier pill nav — 3 top-level pills expanding a
second pill row on click — truer to F's literal single-pill-row shape, at the cost of an extra
click per cross-group jump. See Decision 6.2.

---

## 3. Screen-by-screen wireframes

### 3.1 `a-dash` — Statistics
`.revenue-row` grid (f-analytics) extended to `repeat(4,1fr)`, four `.rev-card`-style tiles:

- "Ads created" **42**, "+12 vs last month" (ok, up-arrow)
- "Ads sold" **11**, "+3 vs last month" (ok, up-arrow)
- "Active leads" **27** — the one dark/loud card, now `--accent`-filled, "2 need a callback
  today" (accent dot, not arrow)
- "Coworkers" **4**, "2 active this week" (mute, no arrow)

Below, full-width `.panel`: "This month" / "Ads created vs sold, day 1–12", Month(on) /
Quarter / Year segmented control in F's nav-pill styling. Chart = f-dashboard's dual-series
hatch-fill SVG grammar repurposed: solid `--accent` filled "Created" area, dashed neutral
"Sold" line, the 12 day-points from the seed series (peak: day 7 · 4 created).

Below that, a new **activity-row-list** component (no F precedent — built from f-workspace's
`.mid-card` row rhythm: icon chip + sentence + relative timestamp, hairline-divided inside a
`.panel`), 5 rows verbatim from seed:
"New lead: Dilnoza Yusupova is interested in your Chilonzor listing" (2 min ago) ·
"Instagram post published — Bright 3-room apartment in Chilonzor is now live" (1 h ago) ·
"Callback reminder — Call Aziz Karimov today at 15:00" (3 h ago) ·
"Listing sold — Two-room flat in Mirobod marked as Sold" (Yesterday) ·
"Sardor Abdullayev created Retail space near Chorsu bazaar" (2 days ago).

### 3.2 `a-listings` — My ads
New `.f-table` primitive inside a `.panel` (F has zero table precedent — the single largest
net-new component, see risks in §5). Toolbar: segmented "All 8 / Active 5 / Sold 1 / Draft 1"
(F nav-pill styling), filter chips "Chilonzor" / "Newest first" (`.control-pill`), secondary
"Export", primary "Add new post". 8 rows, zebra via `--surface-inner`:
`ad1001` Bright 3-room apartment in Chilonzor (pre-selected, accent-tinted row, `#a3f21`,
Active, IG+TG) … `ad1003` Family house with garden in Sergeli (`#c92e8`, "OLX failed" err-tag)
… `ad1005` Two-room flat in Mirobod (`#e5b13`, **Sold** tag, channels "—") … `ad1007`
New-build 4-room in Yashnobod (`#0a4d9`, **Draft** warn tag, "Not published").
Author = single avatar (real photo or initials). Row actions = edit / broadcast / trash.

### 3.3 `a-editor` — Listing editor
Two-column `1fr / 330px`. Left: "Property details" `.panel`, subtitle "Fields mirror the Ad
model", pill-inputs at `14px` radius: Title "Bright 3-room apartment in Chilonzor", City
"Tashkent", District "Chilonzor", Rooms `3`, Area `65`, Storey/Floors `4/9`,
**Repairment "Good"**, **Furniture "Without furniture"** (real Prisma enum strings — not the
old prototype's drifted "Euro"/"Furnished"), Description + Hashtags full-width. Media panel:
5-cell grid, hero photo "Cover" badge, dashed "+" add-tile — the "360°" badge is kept as an
**amber-flagged roadmap proposal** (no `AdMediaType.PANORAMA` yet; Decision 6.3). Right column: Publish panel — IG
(@javlon.realty, checked), TG (2 channels, checked), YouTube (unchecked), **OLX row dimmed
`opacity:.5`, no interactive checkbox**, "Publish to 2 channels" CTA. Visibility panel: Active
toggle ON ("Visible in search results"), "Assign coworker → Sardor Abdullayev" (caret, no
picker wired), Mark as sold toggle OFF.

### 3.4 `a-publish` — Publish status
`.f-table`, 4 rows, one per channel:
Instagram (@javlon.realty, "Full API", **Published** ok, `instagram.com/p/C8x…`,
03.08.2026 | 11:42) · Telegram (@lacasa_tashkent, "Bot API", **Published** ok,
`t.me/lacasa_tashkent/412`) · OLX ("Form fill", **Awaiting review** warn, external "—") ·
YouTube ("Browser OAuth", **Failed** err, "Token expired — reconnect" err-colored external
column). "Retry failed" is the screen's one magenta CTA.

### 3.5 `a-leads` — Leads
`.f-table`, Table(on)/Kanban segmented pills at top, filter chips "All stages" / "All agents",
"Create lead" CTA. 6 rows, initials-avatar colored per stage:
Dilnoza Yusupova (DY, info) "2–3 room apartment, Chilonzor or Yunusobod", $50,000, **New** ·
Aziz Karimov (AK, warn) "Family house, Sergeli", $80,000, **Need to call back** ·
Malika Tosheva (MT, mute) "Office rental, city center", $1,000/month, **Could not connect** ·
Bekzod Nazarov (BN, ok) "2-room flat, Mirobod", $60,000, **Success** (sold · #e5b13) ·
Ravshan Ismoilov (RI, err) "4-room new build, Yashnobod", $100,000, **Rejected** ·
Nodira Ergasheva (NE, info) "1-room studio near metro", $400/month, **New**.

### 3.6 `a-kanban` — Kanban
f-workspace's cut-corner notch card reused directly — the single cleanest F↔console fit in the
whole set. **6 fixed, non-reorderable columns** (New `2` → Could not connect `1` → Need to
call back `1` → Rejected `1` → Accepted `0` → Success `1`), header = colored dot + name +
`em` count pill. Cards: `.card-header` avatar+name → `.mid-card` (phone · budget + interest
text) → `.notch-btn` "advance stage" action in the cut corner. Aziz Karimov's card: warn left
border + footer "⏰ 15:00" tag. Malika's/Ravshan's footers show reason text ("3 attempts" /
"Budget mismatch") instead of an agent name. Bekzod sits in Success with footer "Sold ·
#e5b13". The empty Accepted column shows a dashed ghost tile ("No accepted leads").
**Real drag-and-drop ships in v1** (Decision 6.5): HTML5 drag between columns, with a
required-field modal gate — callback datetime on move to Need-to-call-back, ≥10-char note on
move to Rejected/Accepted, sold-ad reference + note on move to Success.

### 3.7 `a-coworkers` — Coworkers
`.f-table`, filter chip "Under Javlon Rustamov", "Create coworker" CTA. Rows:
Sardor Abdullayev (Coworker, sardor@lacasa.uz, +998 90 111 22 33, 11 listings, 3 closed,
"2 days ago") · Kamola Rashidova (Coworker · under Shahnoza, kamola@lacasa.uz,
+998 90 444 55 66, 8 listings, 2 closed, "Today"). Third row = a dashed
"**+ Create coworker**" ghost row (grafted from the faithful proposal's ghost-tile, adapted to
a table terminal row) so the table doesn't read as broken at n=2.

### 3.8 `a-accounts` — Connected accounts
Two-panel. Left, "Connected accounts" (subtitle "Status switches are read-only indicators",
kept verbatim), 4 rows each = icon + name + status subtext + inert switch (no `data-sw`) +
named action button: Instagram "@javlon.realty · token refreshes 02.10.2026" → Disconnect ·
Telegram "2 channels connected" → Manage · YouTube "Token expired — reconnect required"
(err-text) → **Reconnect (the screen's one magenta urgent CTA)** · OLX "Browser extension
v1.2 detected" → Settings. Right, "Extension" panel — plain `.panel`, **no backdrop-blur/glass
anywhere in the console** (glass belongs to surface 1 only), copy: "The La Casa browser
extension fills OLX and Instagram forms for you, then hands control back so you click Publish
yourself. It never posts on your behalf." + "Open extension settings" CTA.

---

## 4. Data-honesty flags

| Item | Treatment |
|---|---|
| "360°" panorama badge | Kept as **amber-flagged roadmap proposal** in the editor media grid — no `PANORAMA` `AdMediaType`, no Tour model yet, but panorama support is on the product roadmap. (Decision 6.3) |
| `LeadStatus.SUCCESS` ("Closed") | New status decided by the user (deal completed / sold to that lead) — **amber-flagged until the enum member lands in Prisma**. Kanban's 6th column and the Coworkers "Closed" metric both depend on it. (Decision 6.4) |
| Telegram channel display | Count only ("2 channels connected") — `tgChatIds` has no per-channel name field; never fabricate channel names. |
| YouTube/OLX connection status | Inline caption, not a full amber banner: reflects extension/browser-session-detected state, not a stored `ConnectedAccount` row (none exists). |
| Bell unread dot | An "activity since last visit" heuristic against `ActivityEvent` timestamps — the model has no read/unread field, so this is approximate, not a true unread count. |
| Coworkers "Closed" column | **Resolved**: count of that coworker's `Lead` rows with `status=SUCCESS` (Decision 6.4). |
| Leads nav badge `27` vs 6 seeded table rows | Intentional: badge = live aggregate, table = illustrative seed sample. Comment this in code so it isn't "fixed" as a bug later. |
| Repairment/Furniture editor labels | Real Prisma enum values ("Not repaired/Normal/Good/Excellent", "With furniture/Without furniture") — not the old prototype's drifted "Euro"/"Furnished". |
| Rent price format | Standardize on `/month` everywhere (SCREENS.md canon), retiring the console prototype's abbreviated `/mo`. |
| `AdPublication.adId` FK | Treat ad↔publication joins as directionally correct only — schema comment says "no FK yet"; don't assume referential integrity in edge cases. |
| Everything else (Ad fields, Lead fields/statuses, AdPublication channels/statuses, Coworker records) | Real, schema-backed — no flag needed. |
| Never introduced anywhere | View/impression counts, contact-event counts beyond Leads, per-channel post performance (likes/reach), revenue/commission, response-time/SLA metrics, a real Notification model. |

---

## 5. Folder & build architecture

Extend the existing `mockups/build/build.mjs` marker-splice pattern — do not invent a new bundler.

```
mockups/f/
  build/
    build.mjs              # adapted copy of mockups/build/build.mjs — same marker-replace
                           #   splice (fonts/icons/runtime into *.src.html), Poppins woff2
                           #   reused verbatim, no new bundler logic
    f-tokens.css           # single :root{} — one var-naming scheme, one radius scale
                           #   (999/28/14px), one shell (1480px + 28px), one icon-btn size
                           #   set, one avatar-ring technique, accent = magenta not lime
    f-components.css       # topbar, 3-pill zone indicator, labeled rail, icon-btn,
                           #   avatar-stack (photo/initials, no procedural SVG), tag/status
                           #   pill, unified CTA button, NEW: .f-table (row/cell/header,
                           #   --surface-inner zebra), NEW: .f-form (labeled field/select/
                           #   pill-input), notch/cut-corner kanban card (lifted from
                           #   f-workspace as-is)
  f-console.src.html       # single source, 8 <section class="screen" id="a-*">, same
                           #   data-go/data-seg/data-chk/data-sw/data-row attribute contract
                           #   as web-agent.src.html
  f-console.html           # BUILT output — the actual clickable prototype
  PLAN.md                  # this file
```

- **RUNTIME reused unchanged** (hash router, `data-seg`, `data-chk`, `data-sw`, `data-row`,
  theme toggle) — covers every interaction except kanban drag.
- **New JS, small and isolated**: (a) a seed-data block in the same inline
  `window.REGISTRY={}` style as `ICONS`/`PHOTOS`, holding the 8 ads / 6 leads / 2 coworkers /
  4 publications, so `ad1001`, leads and badge counts are provably the same objects
  everywhere, not retyped per screen; (b) **kanban drag module** (in scope per Decision 6.5):
  HTML5 drag-and-drop between the 6 columns + the required-field modal gate, updating column
  counts and card footers on drop.
- **Icons**: extend the shared `ICONS` registry with missing glyphs (bell, gear, search,
  phone, broadcast, arrow-up-right, pencil, trash) rather than hand-inlining new SVGs.
- Charts stay hand-authored inline SVG (project convention, no chart-lib dependency).
- **Build sequence**: tokens + rail + `.f-table` first (unlocks My ads, Publish status, Leads,
  Coworkers — 4 of 8 screens and the highest daily-use surfaces), then Statistics, then the
  editor/`.f-form` primitive, then Kanban last (highest custom-interaction cost).
- Render `f-console.html` in headless Chrome and visually inspect every screen before calling
  any of them done.

---

## 6. Decisions — RESOLVED (user, 04.08.2026)

1. **Accent color** — magenta `#F5439B` was confirmed, built, and then **reversed after the
   user saw it rendered** ("that pink color kills") — final call: the reference lime
   `#CDF44A` everywhere, with dark-olive `#2A3505` text on lime and lime never used as text.
   Primary CTAs are lime with dark-olive labels; charts are dark ink + lime fill.
2. **Nav structure** — ✅ confirmed: 236px labeled rail.
3. **360° panorama** — **on the roadmap** → the "360°" badge stays in the editor media grid as
   an **amber-flagged proposal** (WEB.md banner precedent), not cut. Schema still lacks
   `AdMediaType.PANORAMA` / Tour models; the flag says so.
4. **Lead "Closed" semantics** — a new **`SUCCESS`** ("Closed") lead status is introduced,
   meaning *the deal completed — we sold to that lead*. Distinct from `Accepted` (deal agreed,
   in progress). Consequences:
   - `LeadStatus` enum needs a `SUCCESS` member — **schema change, amber-flagged** until it
     lands in Prisma.
   - Coworkers "Closed" column = count of that coworker's leads with `status=SUCCESS`.
   - Kanban becomes **6 fixed columns** (New → Could not connect → Need to call back →
     Rejected → Accepted → Success), still never reorderable.
   - Seed: Bekzod Nazarov moves `Accepted` → `Success` with footer "Sold · #e5b13" (he bought
     the Two-room flat in Mirobod, the seed's one Sold ad — the two records now corroborate
     each other). The Accepted column then demonstrates the **empty-column state** (dashed
     ghost tile, "No accepted leads").
5. **Kanban drag** — ✅ real drag-and-drop in v1, including the required-field modal gate:
   callback datetime on move to *Need to call back*, ≥10-char note on move to
   *Rejected*/*Accepted*, and sold-ad reference + note on move to *Success*. This is the one
   genuinely new JS module in the build.
