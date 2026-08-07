# La Casa Web — three surfaces, one product

Clickable desktop prototypes for the three audiences the platform actually has. They are built from
the same spec, seed data and brand assets as the mobile mockups (`SCREENS.md`, direction **E ·
Liquid Glass**), so the choice between them is never a choice of design language — it is a choice of
what each audience needs the interface to *do*.

| | File | Role | Screens | Character |
|---|---|---|---|---|
| **1 · Marketplace** | `web-user.html` | signed-out / `USER` | 6 | Consumer storefront. Liquid glass over photography, magenta accent, 22–30px radii. |
| **2 · Console** | `web-agent.html` | `AGENT` / `COWORKER` | 8 | Working instrument. 46px table rows, tabular numerals, photography demoted to a 34px row identifier. |
| **3 · Control room** | `web-admin.html` | `ADMIN` *(proposed)* | 7 | Platform operations. Dark by default, amber signal, monospace records, 38px rows. |

Open any file in a browser. Each has a working hash router (`#/screen-id`), a **Screens** index in the
bottom-right, a **Theme** toggle, and both light and dark themes designed. No network access is
required — fonts, icons and photography are inlined.

---

## Why three designs and not one responsive one

The three surfaces share a brand but not a job, and the differences are load-bearing:

**The marketplace sells.** A buyer visits a handful of times, scans photographs, and leaves. Every
pixel is spent on the property: full-bleed hero, 4-up cards, a sticky map beside scrolling results.
This is the only surface a buyer ever sees, so it is the one that must match the phone app they also
use — it carries mockup-e's `.g` / `.gl` glass primitives unchanged.

**The console works.** An agent lives here six hours a day across eight screens. Cards become rows,
heroes become thumbnails, and decoration becomes signal: magenta marks exactly one thing per screen
(the live metric, the failed channel, the overdue lead) so it still means something at hour six.
Photography is not removed out of taste — it is demoted because a 34px thumbnail identifies a row
faster than a 4:3 card does.

**The control room is dangerous.** An admin holds destructive, irreversible power over other people's
accounts and listings. The single worst failure mode is acting on the wrong surface because it looked
familiar, so this one refuses to look familiar: dark where the console is light, amber where the brand
is magenta, and a permanent environment strip naming the database being written to. Magenta appears
in exactly one place here — destructive confirmation — so the brand colour never reads as "safe".

---

## Screen inventory

### 1 · Marketplace — `web-user.html`

| # | Route | Screen | Contents |
|---|---|---|---|
| 1 | `#/u-home` | Home | Hero + glass search bar, category chips, Featured Listings (4), Top Districts (4), Top Agents (3) |
| 2 | `#/u-search` | Search | Filter rail, 2-up results, sticky price-pin map |
| 3 | `#/u-listing` | Listing detail | Gallery, spec rail, **Live 3D tour**, description, nearby chips, location, price box, booking form |
| 4 | `#/u-agents` | Agents | Directory of all 5 seed agents |
| 5 | `#/u-agent` | Agent profile | Stats, contact channels, their active listings |
| 6 | `#/u-saved` | Saved | Hearted listings |

### 2 · Console — `web-agent.html`

| # | Route | Screen | Web/mobile equivalent |
|---|---|---|---|
| 1 | `#/a-dash` | Statistics | `SCREENS.md` §24 — 4 stat cards + the 12-point series from §4.6 |
| 2 | `#/a-listings` | My ads | §25 — all 8 seed listings with stage, channels, author |
| 3 | `#/a-editor` | Listing editor | §27 — fields mirror the Prisma `Ad` model; media grid; publish panel |
| 4 | `#/a-publish` | Publish status | §29 — one row per (ad, channel), with the real automation tiers from `docs/06` |
| 5 | `#/a-leads` | Leads | §30 — all 6 seed leads |
| 6 | `#/a-kanban` | Kanban | §31 — the 5 fixed columns, order never reorderable |
| 7 | `#/a-coworkers` | Coworkers | §35 |
| 8 | `#/a-accounts` | Connected accounts | §21 — status switches are read-only indicators, per the interaction contract |

### 3 · Control room — `web-admin.html`

| # | Route | Screen | Backed by schema today? |
|---|---|---|---|
| 1 | `#/x-over` | Platform overview | Partly — counts are derivable; MRR and premium counts are not |
| 2 | `#/x-apps` | Realtor applications | **Yes** — `RealtorStatus` / `RealtorKind` / `realtorAppliedAt` already exist |
| 3 | `#/x-users` | Users | Partly — role and realtor status exist; `plan` does not |
| 4 | `#/x-mod` | Listing moderation | Partly — no report/flag model exists |
| 5 | `#/x-tours` | 3D tour review | **No** — proposal only |
| 6 | `#/x-plans` | Plans & premium | **No** — proposal only |
| 7 | `#/x-audit` | Audit log | Partly — `ActivityEvent` exists but has no severity, actor-type or system events |

---

## What these designs assume that the codebase does not have yet

Called out here so nothing in the pixels is mistaken for a decision that has already been made. The
two in-file amber banners on `#/x-tours` and `#/x-plans` say the same thing to anyone reading the
prototype without this document.

1. **There is no `ADMIN` role.** `UserRole` is `USER | AGENT | COWORKER`. Every screen in surface 3
   presumes a fourth member and some way to grant it. `docs/10-backend-for-liquid-glass.md` already
   flags this as a gap for the (unrelated) featured-listing decision.
2. **There is no monetization primitive at all** — no plan, subscription, billing, payment or premium
   concept anywhere in the schema or in `docs/`. The plans screen proposes *two independent axes*
   rather than one flag: a per-agent `User.plan` for capability unlocks (tours, crossposting,
   analytics) and a separate per-ad `Ad.premiumUntil` for placement. They are drawn apart on purpose —
   an agent who owns a 360° camera wants tours on every listing but pays per listing for attention,
   and collapsing both into one flag is the thing that would be painful to unpick later.
3. **Payments would need Payme, Click or Uzum.** `CurrencyCode` is `UZS | USD`; Stripe does not
   operate in Uzbekistan. This is a real integration, and it is fully blocking on charging money.
4. **There is no `Tour` / `TourScene` / `TourHotspot` model** and `AdMediaType` has no `PANORAMA`
   member. The `Live 3D tour` block on the marketplace listing detail, the `360°` badge in the console
   media grid, and the whole tour-review queue are all downstream of that.
5. **No report/flag model** backs the moderation queue's "Duplicate" / "Wrong price" flags.
6. **`ActivityEvent` cannot back the audit log** as drawn — it has no severity, no system actor and no
   structured detail field.

Everything else on surfaces 1 and 2 maps to models that exist today.

---

## How they are built

All three are generated by `mockups/build/build.mjs` from a `.src.html` per surface plus shared assets
lifted verbatim from `mockup-e-liquid-glass.html`, so no asset is hand-inlined twice and the web and
mobile prototypes are guaranteed to render in the same typeface and iconography:

- **Poppins** 400/500/600/700, inlined as woff2 data URIs (42 KB)
- **`window.ICONS`** — 68 [Phosphor](https://phosphoricons.com) glyphs, painted into every `[data-i]`
  at boot. Note the registry stores the glyph body under the short key `b`, not `body`.
- **`window.PHOTOS`** — the same 22 Unsplash JPEGs the mobile mockup uses, painted into every
  `[data-ph]`; `<img>` gets a `src`, anything else gets a `background-image`

Each file is ~665 KB, entirely self-contained, and works offline from `file://`.

**The router is attribute-driven**, the same contract as mockup-e: `data-go` pushes a screen,
`data-back` pops, and `data-fav` / `data-seg` / `data-sw` / `data-chk` / `data-row` wire the
interactive primitives, so new markup needs no new JavaScript.

Routes are written `#/screen-id` rather than `#screen-id` deliberately. A bare fragment that matches
a section id makes the browser scroll that section to the top of the viewport — *after* scripts run,
so the first row of content ends up hidden under the sticky header and no `scrollTo(0,0)` at boot wins
the race. The leading slash matches no element, so the anchor jump never happens.

### Rebuilding

```
node mockups/build/build.mjs   # run from repo root; rewrites mockups/web-{user,agent,admin}.html
```

---

## Seed data

Identical to `SCREENS.md` §4 — the same 8 listings, 6 leads, 5 agents, 5 notifications and 4 dashboard
metrics, with the same formatting rules (`$ {price}` / `$ {price}/month`, `DD.MM.YYYY | HH:MM`,
`+998` phone format, `#` + first 5 UUID characters for ad references). Nothing was invented except
where a screen has no mobile counterpart to inherit from: the admin KPIs and MRR, the plan pricing,
the tour capture metadata (camera model, resolution, scene counts), and the audit-log lines.
